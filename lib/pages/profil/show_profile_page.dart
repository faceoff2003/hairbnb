import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  final String userUuid;

  const UserProfilePage({Key? key, required this.userUuid}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final String apiUrl = 'http://192.168.0.248:8000/api/get_user_profile/${widget.userUuid}/';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print("Réponse brute : ${response.body}"); // Log la réponse

      if (response.statusCode == 200) {
        setState(() {
          userProfile = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erreur : ${response.statusCode} ${response.reasonPhrase}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur réseau : $e";
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil utilisateur"),
        centerTitle: true,
        backgroundColor: const Color(0xFF6D20A5),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : userProfile == null
          ? const Center(child: Text("Aucune donnée à afficher."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: userProfile!['photo_profil'] != null
                    ? NetworkImage(userProfile!['photo_profil'])
                    : const AssetImage('assets/images/default_avatar.png')
                as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "${userProfile!['prenom']} ${userProfile!['nom']}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Type : ${userProfile!['type']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Sexe : ${userProfile!['sexe']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Téléphone : ${userProfile!['numero_telephone']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (userProfile!['type'] == 'coiffeuse') ...[
              const Divider(),
              const Text(
                "Informations professionnelles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Dénomination : ${userProfile!['coiffeuse']['denomination_sociale'] ?? 'Non spécifiée'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "TVA : ${userProfile!['coiffeuse']['tva'] ?? 'Non spécifiée'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Position : ${userProfile!['coiffeuse']['position'] ?? 'Non spécifiée'}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (userProfile!['type'] == 'client') ...[
              const Divider(),
              const Text(
                "Informations client",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Pas d'informations spécifiques pour les clients.",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }


}
