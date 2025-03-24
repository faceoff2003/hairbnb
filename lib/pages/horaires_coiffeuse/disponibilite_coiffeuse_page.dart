// // PAGE FLUTTER POUR GESTION DES HORAIRES ET INDISPONIBILITES - MODERNE

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../models/horaire_coiffeuse.dart';
import '../../models/indisponibilite_coiffeuse.dart';
import '../../widgets/bottom_nav_bar.dart'; // Assure-toi que le chemin est correct

class HoraireIndispoPage extends StatefulWidget {
  final int coiffeuseId;
  const HoraireIndispoPage({required this.coiffeuseId});

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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
      print("Erreur API: $e");
    }
  }

  Future<void> showHoraireDialog(int jour) async {
    final exist = horaires.firstWhere(
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

    TimeOfDay? debut = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
    if (debut == null) return;
    TimeOfDay? fin = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 17, minute: 0));
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
    if (res.statusCode == 200) fetchAll();
  }

  Future<void> addIndisponibilite() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
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
            title: Text("Nouvelle indisponibilité"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text("Journée entière"),
                  value: journeeEntiere,
                  onChanged: (val) => setState(() => journeeEntiere = val ?? false),
                ),
                if (!journeeEntiere)
                  Column(
                    children: [
                      ListTile(
                        title: Text("Heure début: ${debut.format(context)}"),
                        trailing: Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: debut);
                          if (picked != null) setState(() => debut = picked);
                        },
                      ),
                      ListTile(
                        title: Text("Heure fin: ${fin.format(context)}"),
                        trailing: Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: fin);
                          if (picked != null) setState(() => fin = picked);
                        },
                      ),
                    ],
                  ),
                TextField(
                  controller: motifCtrl,
                  decoration: InputDecoration(labelText: "Motif (facultatif)"),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
              ElevatedButton(
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

                  await http.post(
                    Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
                    headers: {"Content-Type": "application/json"},
                    body: body,
                  );
                  Navigator.pop(context);
                  fetchAll();
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
    );
    if (date == null) return;

    TimeOfDay? debut = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureDebut));
    if (debut == null) return;
    TimeOfDay? fin = await showTimePicker(context: context, initialTime: _toTimeOfDay(i.heureFin));
    if (fin == null) return;

    final motifCtrl = TextEditingController(text: i.motif ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Modifier le motif"),
        content: TextField(controller: motifCtrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          TextButton(
            onPressed: () async {
              final body = json.encode({
                "date": DateFormat('yyyy-MM-dd').format(date),
                "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
                "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
                "motif": motifCtrl.text,
              });

              await http.put(
                Uri.parse("https://www.hairbnb.site/api/update_indisponibilite/${i.id}/"),
                headers: {"Content-Type": "application/json"},
                body: body,
              );
              Navigator.pop(context);
              fetchAll();
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
        title: Text("Supprimer"),
        content: Text("Voulez-vous vraiment supprimer cette indisponibilité ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await http.delete(
      Uri.parse("https://www.hairbnb.site/api/delete_indisponibilite/$indispoId/"),
    );
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion des disponibilités"),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addIndisponibilite,
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.all(12),
        children: [
          Text("Horaires hebdomadaires", style: Theme.of(context).textTheme.titleLarge),
          ...jours.asMap().entries.map((e) {
            final jour = e.key;
            HoraireCoiffeuse? exist;
            try {
              exist = horaires.firstWhere((h) => h.jour == jour);
            } catch (e) {
              exist = null;
            }
            return ListTile(
              title: Text(jours[jour]),
              subtitle: exist != null
                  ? Text("${exist.heureDebut} - ${exist.heureFin}")
                  : Text("Non défini"),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: Colors.teal),
                onPressed: () => showHoraireDialog(jour),
              ),
            );
          }),
          Divider(),
          Text("Indisponibilités exceptionnelles", style: Theme.of(context).textTheme.titleLarge),
          ...indispos.map((i) => ListTile(
            title: Text(
              DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(i.date)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${i.heureDebut} - ${i.heureFin}"),
                if (i.motif != null && i.motif!.isNotEmpty) Text("Motif: ${i.motif}"),
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
          )),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
//
// import '../../models/horaire_coiffeuse.dart';
// import '../../models/indisponibilite_coiffeuse.dart';
//
// class HoraireIndispoPage extends StatefulWidget {
//   final int coiffeuseId;
//   const HoraireIndispoPage({required this.coiffeuseId});
//
//   @override
//   State<HoraireIndispoPage> createState() => _HoraireIndispoPageState();
// }
//
// class _HoraireIndispoPageState extends State<HoraireIndispoPage> {
//   List<HoraireCoiffeuse> horaires = [];
//   List<IndisponibiliteCoiffeuse> indispos = [];
//
//   TimeOfDay _toTimeOfDay(String timeStr) {
//     final parts = timeStr.split(":");
//     final hour = int.parse(parts[0]);
//     final minute = int.parse(parts[1]);
//     return TimeOfDay(hour: hour, minute: minute);
//   }
//
//   final jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('fr_FR', null).then((_) => fetchAll());
//   }
//
//   Future<void> fetchAll() async {
//     setState(() => isLoading = true);
//     try {
//       final resHoraire = await http.get(Uri.parse("https://www.hairbnb.site/api/get_horaires_coiffeuse/${widget.coiffeuseId}/"));
//       final resIndispo = await http.get(Uri.parse("https://www.hairbnb.site/api/get_indisponibilites/${widget.coiffeuseId}/"));
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
//       print("Erreur API: $e");
//     }
//   }
//
//   Future<void> showHoraireDialog(int jour) async {
//     final exist = horaires.firstWhere(
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
//     String formatTime(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
//
//     final body = json.encode({
//       "coiffeuse": widget.coiffeuseId,
//       "jour": jour,
//       "heure_debut": formatTime(debut),
//       "heure_fin": formatTime(fin),
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
//                   onChanged: (val) {
//                     setState(() {
//                       journeeEntiere = val ?? false;
//                     });
//                   },
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
//                     "heure_debut": journeeEntiere ? "00:00" : "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//                     "heure_fin": journeeEntiere ? "23:59" : "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
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
//
//
//   // Future<void> addIndisponibilite() async {
//   //   DateTime? date = await showDatePicker(
//   //     context: context,
//   //     initialDate: DateTime.now(),
//   //     firstDate: DateTime.now(),
//   //     lastDate: DateTime.now().add(Duration(days: 365)),
//   //   );
//   //   if (date == null) return;
//   //
//   //   TimeOfDay? debut = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 10, minute: 0));
//   //   if (debut == null) return;
//   //   TimeOfDay? fin = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 16, minute: 0));
//   //   if (fin == null) return;
//   //
//   //   final motifCtrl = TextEditingController();
//   //   await showDialog(
//   //     context: context,
//   //     builder: (_) => AlertDialog(
//   //       title: Text("Motif (facultatif)"),
//   //       content: TextField(controller: motifCtrl),
//   //       actions: [
//   //         TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
//   //         TextButton(
//   //           onPressed: () async {
//   //             final body = json.encode({
//   //               "coiffeuse": widget.coiffeuseId,
//   //               "date": DateFormat('yyyy-MM-dd').format(date),
//   //               "heure_debut": "${debut.hour.toString().padLeft(2, '0')}:${debut.minute.toString().padLeft(2, '0')}",
//   //               "heure_fin": "${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}",
//   //               "motif": motifCtrl.text,
//   //             });
//   //
//   //             final res = await http.post(
//   //               Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
//   //               headers: {"Content-Type": "application/json"},
//   //               body: body,
//   //             );
//   //             Navigator.pop(context);
//   //             if (res.statusCode == 200) fetchAll();
//   //           },
//   //           child: Text("Valider"),
//   //         )
//   //       ],
//   //     ),
//   //   );
//   // }
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
//         child: Icon(Icons.add),
//         backgroundColor: Colors.teal,
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
//
//         ],
//       ),
//     );
//
//
//   }
//
//   Future<void> modifierIndisponibilite(IndisponibiliteCoiffeuse i) async {
//     DateTime initialDate = DateTime.parse(i.date);
//     DateTime? date = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
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
//           TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Supprimer", style: TextStyle(color: Colors.red))),
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
//
// }
//










// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart'; // <-- obligatoire
//
// import '../../models/horaire_coiffeuse.dart';
// import '../../models/indisponibilite_coiffeuse.dart';
//
// class HoraireIndispoPage extends StatefulWidget {
//   final int coiffeuseId;
//   const HoraireIndispoPage({required this.coiffeuseId});
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
//
//   @override
//   void initState() {
//     super.initState();
//     initializeDateFormatting('fr_FR', null).then((_) {
//       fetchAll();
//     });
//   }
//
//   Future<void> fetchAll() async {
//     setState(() => isLoading = true);
//
//     try {
//       final resHoraire = await http.get(Uri.parse("https://www.hairbnb.site/api/get_horaires_coiffeuse/${widget.coiffeuseId}/"));
//       final resIndispo = await http.get(Uri.parse("https://www.hairbnb.site/api/get_indisponibilites/${widget.coiffeuseId}/"));
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
//       } else {
//         print("Erreur lors du chargement des données");
//       }
//     } catch (e) {
//       print("❌ Erreur API : $e");
//     }
//   }
//
//   Future<void> showHoraireDialog(int jour) async {
//     final exist = horaires.firstWhere(
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
//     TimeOfDay? pickedDebut = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(hour: 8, minute: 0),
//     );
//     if (pickedDebut == null) return;
//
//     TimeOfDay? pickedFin = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(hour: 17, minute: 0),
//     );
//     if (pickedFin == null) return;
//
//     String to24h(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
//
//     final body = json.encode({
//       "coiffeuse": widget.coiffeuseId,
//       "jour": jour,
//       "heure_debut": to24h(pickedDebut),
//       "heure_fin": to24h(pickedFin),
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
//     TimeOfDay? debut = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 10, minute: 0));
//     if (debut == null) return;
//
//     TimeOfDay? fin = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 16, minute: 0));
//     if (fin == null) return;
//
//     final motifCtrl = TextEditingController();
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Motif (facultatif)"),
//         content: TextField(controller: motifCtrl),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
//           TextButton(
//             onPressed: () async {
//               String to24h(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
//               final body = json.encode({
//                 "coiffeuse": widget.coiffeuseId,
//                 "date": DateFormat('yyyy-MM-dd').format(date),
//                 "heure_debut": to24h(debut),
//                 "heure_fin": to24h(fin),
//                 "motif": motifCtrl.text,
//               });
//
//               final res = await http.post(
//                 Uri.parse("https://www.hairbnb.site/api/add_indisponibilite/"),
//                 headers: {"Content-Type": "application/json"},
//                 body: body,
//               );
//               Navigator.pop(context);
//               if (res.statusCode == 200) fetchAll();
//               else print("Erreur ajout indispo: ${res.body}");
//             },
//             child: Text("Valider"),
//           )
//         ],
//       ),
//     );
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
//         child: Icon(Icons.add),
//         backgroundColor: Colors.teal,
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
//             } catch (_) {
//               exist = null;
//             }
//
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
//             title: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(i.date))),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("${i.heureDebut} - ${i.heureFin}"),
//                 if (i.motif != null && i.motif!.isNotEmpty) Text("Motif: ${i.motif}"),
//               ],
//             ),
//           )),
//         ],
//       ),
//     );
//   }
// }
