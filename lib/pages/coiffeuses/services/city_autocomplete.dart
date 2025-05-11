import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CityAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onCitySelected;
  final String apiKey;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.apiKey,
    this.onCitySelected,
  });

  Future<List<String>> fetchSuggestions(String query) async {
    if (query.length < 3) return [];

    final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&type=city&lang=fr&limit=5&apiKey=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;

        return features.map<String>((feature) {
          final props = feature['properties'];
          final city = props['city'] ?? props['name'] ?? '';
          final country = props['country'] ?? '';
          return "$city, $country";
        }).toList();
      }
    } catch (e) {
      print("❌ Erreur autocomplete Geoapify : $e");
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
        return await fetchSuggestions(textEditingValue.text);
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (onCitySelected != null) onCitySelected!(selection);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: const InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }
}
