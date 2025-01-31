import 'package:flutter/material.dart';

class SalonCoiffeusePage extends StatelessWidget {
  final Map<String, dynamic> coiffeuse;

  const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupération des données
    String nom = coiffeuse['user']['nom'] ?? "Inconnu";
    String prenom = coiffeuse['user']['prenom'] ?? "";
    String photoProfil = coiffeuse['user']['photo_profil'] ??
        'https://via.placeholder.com/150';
    String denominationSociale = coiffeuse['denomination_sociale'] ?? "Non spécifié";
    String tva = coiffeuse['tva'] ?? "Non renseignée";
    List<dynamic> services = coiffeuse['services'] ?? [];
    String adresse = "${coiffeuse['user']['adresse']['numero'] ?? ''}, "
        "${coiffeuse['user']['adresse']['rue']['nom_rue'] ?? ''}, "
        "${coiffeuse['user']['adresse']['rue']['localite']['commune'] ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: Text("$nom $prenom - Salon"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Photo de profil
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(photoProfil),
              ),
            ),
            const SizedBox(height: 10),

            // 📌 Nom & Dénomination
            Center(
              child: Text(
                "$nom $prenom",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                denominationSociale,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            // 🏡 Adresse
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 5),
                Expanded(child: Text(adresse)),
              ],
            ),
            const SizedBox(height: 10),

            // 📜 TVA
            Row(
              children: [
                const Icon(Icons.business, color: Colors.orange),
                const SizedBox(width: 5),
                Text("TVA : $tva"),
              ],
            ),
            const SizedBox(height: 20),

            // 💇‍♀️ Liste des services
            const Text(
              "Services proposés :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            services.isEmpty
                ? const Text("Aucun service disponible.")
                : Column(
              children: services.map((service) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.cut, color: Colors.orange),
                    title: Text(service['intitule'] ?? "Service"),
                    subtitle: Text("${service['prix']}€ - ${service['temps']} min"),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
