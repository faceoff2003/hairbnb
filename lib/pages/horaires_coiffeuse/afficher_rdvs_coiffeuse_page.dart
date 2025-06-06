import 'package:flutter/material.dart';
import 'package:hairbnb/pages/horaires_coiffeuse/services_horaires_coiffeuse/countdown_box_timer.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_light.dart';
import '../../pages/horaires_coiffeuse/services_horaires_coiffeuse/rdv_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';

class RendezVousPage extends StatefulWidget {
  final int coiffeuseId;

  const RendezVousPage({super.key, required this.coiffeuseId});

  @override
  State<RendezVousPage> createState() => _RendezVousPageState();
}

class _RendezVousPageState extends State<RendezVousPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  int currentIndex = 2;

  List<ReservationLight> actifs = [];
  List<ReservationLight> archives = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      actifs = await RdvService().fetchRendezVous(
        coiffeuseId: widget.coiffeuseId,
        archived: false,
      );

      archives = await RdvService().fetchRendezVous(
        coiffeuseId: widget.coiffeuseId,
        archived: true,
      );
    } catch (e) {
      print("Erreur: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Container(
            color: Colors.orange.shade50,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: const [
                Tab(text: "🟢 Actifs"),
                Tab(text: "📂 Archivés"),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildRdvList(actifs),
                _buildRdvList(archives),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildRdvList(List<ReservationLight> rdvs) {
    if (rdvs.isEmpty) {
      return const Center(child: Text("Aucun rendez-vous."));
    }

    return ListView.builder(
      itemCount: rdvs.length,
      itemBuilder: (context, index) {
        final rdv = rdvs[rdvs.length - 1 - index];
        final dateFormatted = DateFormat("dd MMM yyyy").format(rdv.dateHeure);
        final heureDebut = DateFormat("HH:mm").format(rdv.dateHeure);
        final heureFin = DateFormat("HH:mm").format(
          rdv.dateHeure.add(Duration(minutes: rdv.dureeTotale)),
        );

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundImage: rdv.photoProfil != null
                  ? NetworkImage("https://www.hairbnb.site${rdv.photoProfil}")
                  : const AssetImage("assets/images/avatar_placeholder.png") as ImageProvider,
              radius: 26,
            ),
            title: Text(
              "${rdv.clientPrenom} ${rdv.clientNom}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "$dateFormatted • 🕒 $heureDebut - $heureFin",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "💶 ${rdv.totalPrix.toStringAsFixed(2)} € • ⏱ ${rdv.dureeTotale} min",
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rdv.statut == "confirmé"
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rdv.statut.toUpperCase(),
                    style: TextStyle(
                      color: rdv.statut == "confirmé" ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: "Modifier le rendez-vous",
                      onPressed: () {
                        // 👉 Navigue vers la page de modification ici
                        print("Modifier ${rdv.idRendezVous}");
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: Colors.grey),
                      tooltip: "Archiver ce rendez-vous",
                      onPressed: () {
                        // 👉 Appelle une méthode pour archiver ici
                        print("Archiver ${rdv.idRendezVous}");
                      },
                    ),
                  ],
                )
              ],
            ),

            //trailing: CountdownTimerWidget(targetTime: rdv.dateHeure),
            //trailing: CountdownTimerWidget(targetTime: rdv.dateHeure),
            trailing: CountdownBoxTimer(targetTime: rdv.dateHeure),

            isThreeLine: true,
          ),
        );
      },
    );
  }
}
