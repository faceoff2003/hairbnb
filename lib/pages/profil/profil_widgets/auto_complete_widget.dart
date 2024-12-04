import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StreetAutocomplete extends StatefulWidget {
  final TextEditingController streetController;

  const StreetAutocomplete({
    Key? key,
    required this.streetController,
  }) : super(key: key);

  @override
  State<StreetAutocomplete> createState() => _StreetAutocompleteState();
}

class _StreetAutocompleteState extends State<StreetAutocomplete> {
  List<String> suggestions = [];

  Future<void> fetchStreetSuggestions(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
        "https://api-adresse-belgique.be/search?street=$query");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          suggestions = (data['results'] as List)
              .map((item) => item['street'].toString())
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur API : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        await fetchStreetSuggestions(textEditingValue.text);
        return suggestions;
      },
      onSelected: (String selection) {
        widget.streetController.text = selection;
      },
      fieldViewBuilder:
          (context, controller, focusNode, onEditingComplete) {
        widget.streetController.text = controller.text;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: const InputDecoration(
            labelText: "Rue",
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }
}
