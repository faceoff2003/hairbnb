import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommuneAutoFill extends StatefulWidget {
  final TextEditingController codePostalController;
  final TextEditingController communeController;

  const CommuneAutoFill({
    Key? key,
    required this.codePostalController,
    required this.communeController,
  }) : super(key: key);

  @override
  State<CommuneAutoFill> createState() => _CommuneAutoFillState();
}

class _CommuneAutoFillState extends State<CommuneAutoFill> {
  Future<void> fetchCommune(String codePostal) async {
    if (codePostal.isEmpty) return;

    final url = Uri.parse("https://api-adresse-belgique.be/commune?code_postal=$codePostal");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['commune'] != null) {
          setState(() {
            widget.communeController.text = data['commune'];
          });
        }
      } else {
        widget.communeController.text = "";
      }
    } catch (e) {
      debugPrint("Erreur : $e");
      widget.communeController.text = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.codePostalController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Code Postal",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => fetchCommune(value),
    );
  }
}
