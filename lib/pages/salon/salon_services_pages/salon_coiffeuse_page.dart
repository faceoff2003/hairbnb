import 'package:flutter/material.dart';
import 'package:hairbnb/models/services.dart';
import 'package:hairbnb/models/coiffeuse.dart';
import 'package:hairbnb/pages/chat/chat_page.dart';
import 'package:hairbnb/pages/salon/salon_services_pages/show_services_list_page.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class SalonCoiffeusePage extends StatefulWidget {
  final Coiffeuse coiffeuse;

  const SalonCoiffeusePage({super.key, required this.coiffeuse});

  @override
  _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
}

class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
  List<Service> services = [];
  bool isLoading = true;
  bool isExpandedInfo = false;
  bool isExpandedServices = false;
  int? salonId;


  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    final String apiUrl =
        'https://www.hairbnb.site/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        Map<String, dynamic> responseData = json.decode(decodedBody);

        if (responseData['status'] == 'success' && responseData['salon'] != null) {
          List<dynamic> serviceList = responseData['salon']['services'] ?? [];
          salonId = responseData['salon']['id']; // ✅ récupération

          setState(() {
            services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// **📩 Ouvrir le chat avec la coiffeuse**
  void _contactCoiffeuse() {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur : Vous devez être connecté pour envoyer un message."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          currentUser: currentUser,
          otherUserId: widget.coiffeuse.uuid,
        ),
      ),
    );
  }

  /// **🔍 Afficher la liste complète des services**
  void _afficherServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesListPage(
          coiffeuseId: widget.coiffeuse.idTblUser.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.orange.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 Photo de profil
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: widget.coiffeuse.photoProfil != null &&
                      widget.coiffeuse.photoProfil!.isNotEmpty
                      ? NetworkImage('https://www.hairbnb.site${widget.coiffeuse.photoProfil}')
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),

              // 📌 Nom & Dénomination
              Center(
                child: Text(
                  "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Center(
                child: Text(
                  widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // 📋 Informations générales
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: const Text(
                    "Informations générales",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  children: [
                    ListTile(
                      title: Text("📞 Téléphone : ${widget.coiffeuse.numeroTelephone}"),
                    ),
                    ListTile(
                      title: Text("📧 Email : ${widget.coiffeuse.email}"),
                    ),
                    ListTile(
                      title: Text("📍 Adresse : ${widget.coiffeuse.nomRue ?? ''}, ${widget.coiffeuse.commune ?? ''}"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  initiallyExpanded: isExpandedServices,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      isExpandedServices = expanded;
                    });
                  },
                  title: const Text(
                    "Services proposés",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  children: services.isEmpty
                      ? [
                    const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        "Aucun service disponible.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  ]
                      : services.map((service) {

                    return ListTile(
                      leading: const Icon(Icons.cut, color: Colors.orange),
                      title: Text(service.intitule),
                      subtitle: Text("💰 ${service.prix}€  ⏳ ${service.temps} min"),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 🟠 **Boutons d'action : "Contacter" et "Afficher les services"**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _contactCoiffeuse,
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text("Contacter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _afficherServices, // ✅ Nouveau bouton "Afficher les services"
                    icon: const Icon(Icons.list, color: Colors.white),
                    label: const Text("Afficher les services"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}