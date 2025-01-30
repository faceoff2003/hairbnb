import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddServicePage extends StatefulWidget {
  final String coiffeuseId;

  const AddServicePage({Key? key, required this.coiffeuseId}) : super(key: key);

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  bool isLoading = false;

  Future<void> _addService() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        durationController.text.isEmpty) {
      _showError("Tous les champs sont obligatoires.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.248:8000/api/add_service_to_salon/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.coiffeuseId,
          'intitule_service': nameController.text,
          'description': descriptionController.text,
          'prix': double.parse(priceController.text),
          'temps_minutes': int.parse(durationController.text),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Service ajouté avec succès."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError("Erreur lors de l'ajout : ${response.body}");
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
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom du service"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Prix (€)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: "Durée (minutes)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addService,
              child: isLoading ? const CircularProgressIndicator() : const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }
}
