import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/Services.dart';

class EditServicePage extends StatefulWidget {
  final Service service;
  final Function onServiceUpdated; // Callback pour rafraîchir la liste

  const EditServicePage({Key? key, required this.service, required this.onServiceUpdated}) : super(key: key);

  @override
  _EditServicePageState createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  late TextEditingController _serviceController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;
  late TextEditingController _tempsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: widget.service.intitule);
    _descriptionController = TextEditingController(text: widget.service.description);
    _prixController = TextEditingController(text: widget.service.prix.toString());
    _tempsController = TextEditingController(text: widget.service.temps.toString());
  }

  Future<void> _updateService() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://192.168.0.248:8000/api/update_service/${widget.service.id}/');

    Service updatedService = Service(
      id: widget.service.id,
      intitule: _serviceController.text,
      description: _descriptionController.text,
      prix: double.parse(_prixController.text),
      temps: int.parse(_tempsController.text),
    );

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedService.toJson()),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Service mis à jour"), backgroundColor: Colors.green),
        );
        widget.onServiceUpdated(); // Rafraîchir la liste
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Erreur lors de la mise à jour"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au serveur."), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le service")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _serviceController, decoration: const InputDecoration(labelText: "Nom du service")),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: _prixController, decoration: const InputDecoration(labelText: "Prix (€)"), keyboardType: TextInputType.number),
            TextField(controller: _tempsController, decoration: const InputDecoration(labelText: "Temps (min)"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _updateService, child: const Text("Mettre à jour")),
          ],
        ),
      ),
    );
  }
}