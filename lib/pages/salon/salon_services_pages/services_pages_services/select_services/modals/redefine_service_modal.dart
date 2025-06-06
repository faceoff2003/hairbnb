import 'package:flutter/material.dart';
import '../../../../../../models/services.dart';

class PrixDureeDialog extends StatefulWidget {
  final Service service;
  final Function(double prix, int dureeMinutes) onConfirm;

  const PrixDureeDialog({
    super.key,
    required this.service,
    required this.onConfirm,
  });

  @override
  State<PrixDureeDialog> createState() => _PrixDureeDialogState();
}

class _PrixDureeDialogState extends State<PrixDureeDialog> {
  final TextEditingController prixController = TextEditingController();
  final TextEditingController dureeController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    prixController.dispose();
    dureeController.dispose();
    super.dispose();
  }

  /// Widget pour les suggestions rapides
  Widget _construireChipSuggestion(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7B61FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF7B61FF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF7B61FF), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text("Configurer le service", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info du service
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.intitule,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (widget.service.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.service.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Champ Prix
              Text(
                "Prix du service *",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: prixController,
                decoration: InputDecoration(
                  hintText: "Ex: 25.00",
                  prefixIcon: const Icon(Icons.euro, size: 20),
                  suffixText: "€",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7B61FF)),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un prix';
                  }
                  final prix = double.tryParse(value);
                  if (prix == null || prix <= 0) {
                    return 'Veuillez saisir un prix valide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Champ Durée
              Text(
                "Durée du service *",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: dureeController,
                decoration: InputDecoration(
                  hintText: "Ex: 30",
                  prefixIcon: const Icon(Icons.schedule, size: 20),
                  suffixText: "min",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7B61FF)),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une durée';
                  }
                  final duree = int.tryParse(value);
                  if (duree == null || duree <= 0) {
                    return 'Veuillez saisir une durée valide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Suggestions rapides
              Text(
                "Suggestions rapides :",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _construireChipSuggestion("25€ - 30min", () {
                    prixController.text = "25.00";
                    dureeController.text = "30";
                  }),
                  _construireChipSuggestion("35€ - 45min", () {
                    prixController.text = "35.00";
                    dureeController.text = "45";
                  }),
                  _construireChipSuggestion("50€ - 60min", () {
                    prixController.text = "50.00";
                    dureeController.text = "60";
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Annuler",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final prix = double.parse(prixController.text);
              final duree = int.parse(dureeController.text);

              Navigator.of(context).pop();
              widget.onConfirm(prix, duree);
            }
          },
          icon: const Icon(Icons.add_circle),
          label: const Text("Ajouter ce service"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B61FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

}

/// Méthode statique pour afficher le dialogue
class PrixDureeDialogHelper {
  static Future<void> afficher({
    required BuildContext context,
    required Service service,
    required Function(double prix, int dureeMinutes) onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PrixDureeDialog(
          service: service,
          onConfirm: onConfirm,
        );
      },
    );
  }
}