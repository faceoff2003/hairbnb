import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HoraireSalonPage extends StatefulWidget {
  final int coiffeuseId; // 🔥 On ne passe plus salonId, mais coiffeuseId

  const HoraireSalonPage({super.key, required this.coiffeuseId});

  @override
  _HoraireSalonPageState createState() => _HoraireSalonPageState();
}

class _HoraireSalonPageState extends State<HoraireSalonPage> {
  int? salonId;
  bool isLoading = true;
  Map<int, Map<String, String>> horaires = {}; // jour : {heure_debut, heure_fin}
  final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];

  @override
  void initState() {
    super.initState();
    fetchSalonEtHoraires();
  }

  Future<void> fetchSalonEtHoraires() async {
    final salonResponse = await http.get(
      Uri.parse('https://www.hairbnb.site/api/get_salon_by_coiffeuse/${widget.coiffeuseId}/'),
    );

    if (salonResponse.statusCode == 200) {
      final data = json.decode(salonResponse.body);
      salonId = data['idSalon'];
      await fetchHoraires(); // 🔁 Ensuite on charge les horaires
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : Salon introuvable ❌")),
      );
    }
  }

  Future<void> fetchHoraires() async {
    final url = Uri.parse('https://www.hairbnb.site/api/get_horaires_salon/${widget.coiffeuseId}/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        horaires = {
          for (var h in data)
            h['jour']: {
              'heure_debut': h['heure_debut'],
              'heure_fin': h['heure_fin'],
              'id': h['id'].toString()
            }
        };
        isLoading = false;
      });
    }
  }

  Future<void> showEditDialog(int jour) async {
    final debutController = TextEditingController(
        text: horaires[jour]?['heure_debut'] ?? "08:00");
    final finController = TextEditingController(
        text: horaires[jour]?['heure_fin'] ?? "18:00");

    final isEditing = horaires.containsKey(jour);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${jours[jour]} - ${isEditing ? "Modifier" : "Ajouter"}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: debutController,
              decoration: const InputDecoration(labelText: "Heure de début (HH:mm)"),
            ),
            TextField(
              controller: finController,
              decoration: const InputDecoration(labelText: "Heure de fin (HH:mm)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Enregistrer"),
            onPressed: () async {
              if (salonId == null) return;

              final payload = {
                "salon": salonId,
                "jour": jour,
                "heure_debut": debutController.text,
                "heure_fin": finController.text,
              };

              final response = await http.post(
                Uri.parse("https://www.hairbnb.site/api/set_horaire_jour/"),
                headers: {"Content-Type": "application/json"},
                body: json.encode(payload),
              );

              if (response.statusCode == 200) {
                Navigator.pop(context);
                fetchHoraires();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Horaire enregistré ✅")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteHoraire(int jour) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer l'horaire"),
        content: Text("Supprimer l'horaire de ${jours[jour]} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );

    if (confirm == true && salonId != null) {
      final response = await http.delete(
        Uri.parse("https://www.hairbnb.site/api/delete_horaire_jour/$salonId/$jour"),
      );

      if (response.statusCode == 200) {
        fetchHoraires();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Horaire supprimé ✅")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🕒 Horaires du salon"), backgroundColor: Colors.orange),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          final horaire = horaires[index];
          return ListTile(
            title: Text(jours[index]),
            subtitle: horaire != null
                ? Text("${horaire['heure_debut']} - ${horaire['heure_fin']}")
                : const Text("Aucun horaire défini"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(horaire != null ? Icons.edit : Icons.add, color: Colors.blue),
                  onPressed: () => showEditDialog(index),
                ),
                if (horaire != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteHoraire(index),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
