// PAGE FLUTTER POUR GESTION DES HORAIRES ET INDISPONIBILITES - MODERNE

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../models/horaire_coiffeuse.dart';
import '../../models/indisponibilite_coiffeuse.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';

class HoraireIndispoPage extends StatefulWidget {
  final int coiffeuseId;
  const HoraireIndispoPage({super.key, required this.coiffeuseId});

  @override
  State<HoraireIndispoPage> createState() => _HoraireIndispoPageState();
}

class _HoraireIndispoPageState extends State<HoraireIndispoPage> {
  List<HoraireCoiffeuse> horaires = [];
  List<IndisponibiliteCoiffeuse> indispos = [];
  final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
  bool isLoading = true;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) => fetchAll());
  }



  TimeOfDay _toTimeOfDay(String timeStr) {
    final parts = timeStr.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> fetchAll() async {
    setState(() => isLoading = true);
    try {
      final resHoraire = await http.get(
          Uri.parse("https://www.hairbnb.site/api/get_horaires_coiffeuse/${widget.coiffeuseId}/"));
      final resIndispo = await http.get(
          Uri.parse("https://www.hairbnb.site/api/get_indisponibilites/${widget.coiffeuseId}/"));

      if (resHoraire.statusCode == 200 && resIndispo.statusCode == 200) {
        final dataHoraires = json.decode(resHoraire.body) as List;
        final dataIndispo = json.decode(resIndispo.body) as List;

        setState(() {
          horaires = dataHoraires.map((e) => HoraireCoiffeuse.fromJson(e)).toList();
          indispos = dataIndispo.map((e) => IndisponibiliteCoiffeuse.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur API: $e");
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> showHoraireDialog(int jour) async {
    horaires.firstWhere(
          (h) => h.jour == jour,
      orElse: () => HoraireCoiffeuse(
        id: 0,
        coiffeuseId: widget.coiffeuseId,
        jour: jour,
        jourLabel: jours[jour],
        heureDebut: "08:00",
        heureFin: "17:00",
      ),
    );

    TimeOfDay? debut = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (debut == null) return;

    TimeOfDay? fin = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (fin == null) return;

    final body = json.encode({
      "coiffeuse": widget.coiffeuseId,
      "jour": jour,
      "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
      "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
    });

    final res = await http.post(
      Uri.parse("https://www.hairbnb.site/api/set_horaire_coiffeuse/"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (res.statusCode == 200) {
      fetchAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Horaire mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> addIndisponibilite() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    TimeOfDay debut = TimeOfDay(hour: 10, minute: 0);
    TimeOfDay fin = TimeOfDay(hour: 16, minute: 0);
    bool journeeEntiere = false;
    final motifCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.teal),
                SizedBox(width: 8),
                Text("Nouvelle indisponibilité"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 2,
                    child: CheckboxListTile(
                      title: Text("Journée entière"),
                      subtitle: Text("Indisponible toute la journée"),
                      value: journeeEntiere,
                      activeColor: Colors.teal,
                      onChanged: (val) => setState(() => journeeEntiere = val ?? false),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (!journeeEntiere)
                    Column(
                      children: [
                        Card(
                          elevation: 1,
                          child: ListTile(
                            leading: Icon(Icons.access_time, color: Colors.teal),
                            title: Text("Heure début"),
                            subtitle: Text(debut.format(context)),
                            trailing: Icon(Icons.edit, color: Colors.grey),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: debut,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.teal,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) setState(() => debut = picked);
                            },
                          ),
                        ),
                        SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          child: ListTile(
                            leading: Icon(Icons.access_time_filled, color: Colors.teal),
                            title: Text("Heure fin"),
                            subtitle: Text(fin.format(context)),
                            trailing: Icon(Icons.edit, color: Colors.grey),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: fin,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.teal,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) setState(() => fin = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 12),
                  TextField(
                    controller: motifCtrl,
                    decoration: InputDecoration(
                      labelText: "Motif",
                      hintText: "Ex: Congés, formation...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.note, color: Colors.teal),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Annuler", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final body = json.encode({
                    "coiffeuse": widget.coiffeuseId,
                    "date": DateFormat('yyyy-MM-dd').format(date),
                    "heure_debut": journeeEntiere
                        ? "00:00"
                        : "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
                    "heure_fin": journeeEntiere
                        ? "23:59"
                        : "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
                    "motif": motifCtrl.text,
                  });

                  final res = await http.post(
                    Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
                    headers: {"Content-Type": "application/json"},
                    body: body,
                  );
                  Navigator.pop(context);
                  if (res.statusCode == 200) {
                    fetchAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Indisponibilité ajoutée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text("Valider"),
              )
            ],
          );
        });
      },
    );
  }

  Future<void> modifierIndisponibilite(IndisponibiliteCoiffeuse i) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(i.date),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    TimeOfDay? debut = await showTimePicker(
      context: context,
      initialTime: _toTimeOfDay(i.heureDebut),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (debut == null) return;

    TimeOfDay? fin = await showTimePicker(
      context: context,
      initialTime: _toTimeOfDay(i.heureFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (fin == null) return;

    final motifCtrl = TextEditingController(text: i.motif ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.orange),
            SizedBox(width: 8),
            Text("Modifier l'indisponibilité"),
          ],
        ),
        content: TextField(
          controller: motifCtrl,
          decoration: InputDecoration(
            labelText: "Motif",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.note, color: Colors.orange),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final body = json.encode({
                "date": DateFormat('yyyy-MM-dd').format(date),
                "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
                "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
                "motif": motifCtrl.text,
              });

              final res = await http.put(
                Uri.parse("https://www.hairbnb.site/api/update_indisponibilite/${i.id}/"),
                headers: {"Content-Type": "application/json"},
                body: body,
              );
              Navigator.pop(context);
              if (res.statusCode == 200) {
                fetchAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Indisponibilité modifiée avec succès'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text("Valider"),
          )
        ],
      ),
    );
  }

  Future<void> supprimerIndisponibilite(int indispoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Confirmer la suppression"),
          ],
        ),
        content: Text("Voulez-vous vraiment supprimer cette indisponibilité ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await http.delete(
      Uri.parse("https://www.hairbnb.site/api/delete_indisponibilite/$indispoId/"),
    );
    if (res.statusCode == 200) {
      fetchAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Indisponibilité supprimée avec succès'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AJOUT : CustomAppBar
      appBar: const CustomAppBar(),

      // ✅ AJOUT : FloatingActionButton amélioré
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addIndisponibilite,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text("Indisponibilité"),
      ),

      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Chargement des disponibilités...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ AJOUT : Titre de la page stylisé
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes Disponibilités',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gestion des horaires et indisponibilités',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Section Horaires
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.teal, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Horaires hebdomadaires",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...jours.asMap().entries.map((e) {
                      final jour = e.key;
                      HoraireCoiffeuse? exist;
                      try {
                        exist = horaires.firstWhere((h) => h.jour == jour);
                      } catch (e) {
                        exist = null;
                      }
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: exist != null ? Colors.teal.shade100 : Colors.grey.shade200,
                            child: Text(
                              jours[jour].substring(0, 1),
                              style: TextStyle(
                                color: exist != null ? Colors.teal : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            jours[jour],
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: exist != null
                              ? Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.teal),
                              SizedBox(width: 4),
                              Text("${exist.heureDebut} - ${exist.heureFin}"),
                            ],
                          )
                              : Row(
                            children: [
                              Icon(Icons.schedule_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Text("Non défini", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => showHoraireDialog(jour),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Section Indisponibilités
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_busy, color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Indisponibilités exceptionnelles",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (indispos.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.event_available, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                "Aucune indisponibilité",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Vous êtes disponible selon vos horaires",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...indispos.map((i) => Card(
                        elevation: 1,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: Icon(Icons.event_busy, color: Colors.red, size: 20),
                          ),
                          title: Text(
                            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(i.date)),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text("${i.heureDebut} - ${i.heureFin}"),
                                ],
                              ),
                              if (i.motif != null && i.motif!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.note, size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Flexible(child: Text("${i.motif}", style: TextStyle(color: Colors.grey))),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => modifierIndisponibilite(i),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => supprimerIndisponibilite(i.id),
                              ),
                            ],
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),

            // ✅ AJOUT : Espace en bas pour éviter que le contenu soit masqué par la navbar
            SizedBox(height: 100),
          ],
        ),
      ),

      // ✅ AJOUT : BottomNavBar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

















// // // PAGE FLUTTER POUR GESTION DES HORAIRES ET INDISPONIBILITES - MODERNE
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
//
// import '../../models/horaire_coiffeuse.dart';
// import '../../models/indisponibilite_coiffeuse.dart';
// import '../../widgets/bottom_nav_bar.dart'; // Assure-toi que le chemin est correct
//
// class HoraireIndispoPage extends StatefulWidget {
//   final int coiffeuseId;
//   const HoraireIndispoPage({super.key, required this.coiffeuseId});
//
//   @override
//   State<HoraireIndispoPage> createState() => _HoraireIndispoPageState();
// }
//
// class _HoraireIndispoPageState extends State<HoraireIndispoPage> {
//   List<HoraireCoiffeuse> horaires = [];
//   List<IndisponibiliteCoiffeuse> indispos = [];
//   final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
//   bool isLoading = true;
//   int _currentIndex = 2;
//
//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('fr_FR', null).then((_) => fetchAll());
//   }
//
//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }
//
//   TimeOfDay _toTimeOfDay(String timeStr) {
//     final parts = timeStr.split(":");
//     return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
//   }
//
//   Future<void> fetchAll() async {
//     setState(() => isLoading = true);
//     try {
//       final resHoraire = await http.get(
//           Uri.parse("https://www.hairbnb.site/api/get_horaires_coiffeuse/${widget.coiffeuseId}/"));
//       final resIndispo = await http.get(
//           Uri.parse("https://www.hairbnb.site/api/get_indisponibilites/${widget.coiffeuseId}/"));
//
//       if (resHoraire.statusCode == 200 && resIndispo.statusCode == 200) {
//         final dataHoraires = json.decode(resHoraire.body) as List;
//         final dataIndispo = json.decode(resIndispo.body) as List;
//
//         setState(() {
//           horaires = dataHoraires.map((e) => HoraireCoiffeuse.fromJson(e)).toList();
//           indispos = dataIndispo.map((e) => IndisponibiliteCoiffeuse.fromJson(e)).toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("Erreur API: $e");
//       }
//     }
//   }
//
//   Future<void> showHoraireDialog(int jour) async {
//     horaires.firstWhere(
//           (h) => h.jour == jour,
//       orElse: () => HoraireCoiffeuse(
//         id: 0,
//         coiffeuseId: widget.coiffeuseId,
//         jour: jour,
//         jourLabel: jours[jour],
//         heureDebut: "08:00",
//         heureFin: "17:00",
//       ),
//     );
//
//     TimeOfDay? debut = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
//     if (debut == null) return;
//     TimeOfDay? fin = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 17, minute: 0));
//     if (fin == null) return;
//
//     final body = json.encode({
//       "coiffeuse": widget.coiffeuseId,
//       "jour": jour,
//       "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//       "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//     });
//
//     final res = await http.post(
//       Uri.parse("https://www.hairbnb.site/api/set_horaire_coiffeuse/"),
//       headers: {"Content-Type": "application/json"},
//       body: body,
//     );
//     if (res.statusCode == 200) fetchAll();
//   }
//
//   Future<void> addIndisponibilite() async {
//     DateTime? date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 365)),
//     );
//     if (date == null) return;
//
//     TimeOfDay debut = TimeOfDay(hour: 10, minute: 0);
//     TimeOfDay fin = TimeOfDay(hour: 16, minute: 0);
//     bool journeeEntiere = false;
//     final motifCtrl = TextEditingController();
//
//     await showDialog(
//       context: context,
//       builder: (ctx) {
//         return StatefulBuilder(builder: (context, setState) {
//           return AlertDialog(
//             title: Text("Nouvelle indisponibilité"),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CheckboxListTile(
//                   title: Text("Journée entière"),
//                   value: journeeEntiere,
//                   onChanged: (val) => setState(() => journeeEntiere = val ?? false),
//                 ),
//                 if (!journeeEntiere)
//                   Column(
//                     children: [
//                       ListTile(
//                         title: Text("Heure début: ${debut.format(context)}"),
//                         trailing: Icon(Icons.access_time),
//                         onTap: () async {
//                           final picked = await showTimePicker(context: context, initialTime: debut);
//                           if (picked != null) setState(() => debut = picked);
//                         },
//                       ),
//                       ListTile(
//                         title: Text("Heure fin: ${fin.format(context)}"),
//                         trailing: Icon(Icons.access_time),
//                         onTap: () async {
//                           final picked = await showTimePicker(context: context, initialTime: fin);
//                           if (picked != null) setState(() => fin = picked);
//                         },
//                       ),
//                     ],
//                   ),
//                 TextField(
//                   controller: motifCtrl,
//                   decoration: InputDecoration(labelText: "Motif (facultatif)"),
//                 )
//               ],
//             ),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
//               ElevatedButton(
//                 onPressed: () async {
//                   final body = json.encode({
//                     "coiffeuse": widget.coiffeuseId,
//                     "date": DateFormat('yyyy-MM-dd').format(date),
//                     "heure_debut": journeeEntiere
//                         ? "00:00"
//                         : "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//                     "heure_fin": journeeEntiere
//                         ? "23:59"
//                         : "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//                     "motif": motifCtrl.text,
//                   });
//
//                   await http.post(
//                     Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
//                     headers: {"Content-Type": "application/json"},
//                     body: body,
//                   );
//                   Navigator.pop(context);
//                   fetchAll();
//                 },
//                 child: Text("Valider"),
//               )
//             ],
//           );
//         });
//       },
//     );
//   }
//
//   Future<void> modifierIndisponibilite(IndisponibiliteCoiffeuse i) async {
//     DateTime? date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.parse(i.date),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 365)),
//     );
//     if (date == null) return;
//
//     TimeOfDay? debut = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureDebut));
//     if (debut == null) return;
//     TimeOfDay? fin = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureFin));
//     if (fin == null) return;
//
//     final motifCtrl = TextEditingController(text: i.motif ?? "");
//
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Modifier le motif"),
//         content: TextField(controller: motifCtrl),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
//           TextButton(
//             onPressed: () async {
//               final body = json.encode({
//                 "date": DateFormat('yyyy-MM-dd').format(date),
//                 "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//                 "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//                 "motif": motifCtrl.text,
//               });
//
//               await http.put(
//                 Uri.parse("https://www.hairbnb.site/api/update_indisponibilite/${i.id}/"),
//                 headers: {"Content-Type": "application/json"},
//                 body: body,
//               );
//               Navigator.pop(context);
//               fetchAll();
//             },
//             child: Text("Valider"),
//           )
//         ],
//       ),
//     );
//   }
//
//   Future<void> supprimerIndisponibilite(int indispoId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Supprimer"),
//         content: Text("Voulez-vous vraiment supprimer cette indisponibilité ?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Annuler")),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text("Supprimer", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//     if (confirm != true) return;
//
//     await http.delete(
//       Uri.parse("https://www.hairbnb.site/api/delete_indisponibilite/$indispoId/"),
//     );
//     fetchAll();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Gestion des disponibilités"),
//         backgroundColor: Colors.teal,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: addIndisponibilite,
//         backgroundColor: Colors.teal,
//         child: Icon(Icons.add),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView(
//         padding: EdgeInsets.all(12),
//         children: [
//           Text("Horaires hebdomadaires", style: Theme.of(context).textTheme.titleLarge),
//           ...jours.asMap().entries.map((e) {
//             final jour = e.key;
//             HoraireCoiffeuse? exist;
//             try {
//               exist = horaires.firstWhere((h) => h.jour == jour);
//             } catch (e) {
//               exist = null;
//             }
//             return ListTile(
//               title: Text(jours[jour]),
//               subtitle: exist != null
//                   ? Text("${exist.heureDebut} - ${exist.heureFin}")
//                   : Text("Non défini"),
//               trailing: IconButton(
//                 icon: Icon(Icons.edit, color: Colors.teal),
//                 onPressed: () => showHoraireDialog(jour),
//               ),
//             );
//           }),
//           Divider(),
//           Text("Indisponibilités exceptionnelles", style: Theme.of(context).textTheme.titleLarge),
//           ...indispos.map((i) => ListTile(
//             title: Text(
//               DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(i.date)),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("${i.heureDebut} - ${i.heureFin}"),
//                 if (i.motif != null && i.motif!.isNotEmpty) Text("Motif: ${i.motif}"),
//               ],
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.edit, color: Colors.orange),
//                   onPressed: () => modifierIndisponibilite(i),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.delete, color: Colors.red),
//                   onPressed: () => supprimerIndisponibilite(i.id),
//                 ),
//               ],
//             ),
//           )),
//         ],
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: _onTabTapped,
//       ),
//     );
//   }
// }