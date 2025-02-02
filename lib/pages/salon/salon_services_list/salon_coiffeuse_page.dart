import 'package:flutter/material.dart';
import 'package:hairbnb/models/Services.dart';
import 'package:hairbnb/models/coiffeuse.dart';
import 'package:hairbnb/pages/chat/chat_page.dart';
import 'package:hairbnb/pages/salon/salon_services_list/show_services_list_page.dart';
//import 'package:hairbnb/pages/salon/services_list_page.dart'; // ✅ Importation de ServicesListPage
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/Custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class SalonCoiffeusePage extends StatefulWidget {
  final Coiffeuse coiffeuse;

  const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);

  @override
  _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
}

class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
  List<Service> services = [];
  bool isLoading = true;
  bool isExpandedInfo = false;
  bool isExpandedServices = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    final String apiUrl =
        'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        Map<String, dynamic> responseData = json.decode(decodedBody);

        if (responseData['status'] == 'success' && responseData['salon'] != null) {
          List<dynamic> serviceList = responseData['salon']['services'] ?? [];
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
                      ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
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
                      title: Text("📞 Téléphone : ${widget.coiffeuse.numeroTelephone ?? 'Non renseigné'}"),
                    ),
                    ListTile(
                      title: Text("📧 Email : ${widget.coiffeuse.email ?? 'Non renseigné'}"),
                    ),
                    ListTile(
                      title: Text("📍 Adresse : ${widget.coiffeuse.nomRue ?? ''}, ${widget.coiffeuse.commune ?? ''}"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 💇‍♀️ Services ExpansionTile (ON GARDE CETTE PARTIE ✅)
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






































// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:hairbnb/pages/chat/chat_page.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/Custom_app_bar.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import 'package:provider/provider.dart';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpandedInfo = false; // État pour l'ExpansionTile des infos générales
//   bool isExpandedServices = false; // État pour l'ExpansionTile des services
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _contactCoiffeuse() {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context, listen: false);
//     final currentUser = currentUserProvider.currentUser;
//
//     if (currentUser == null) {
//       print("❌ Erreur : Aucun utilisateur connecté.");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Erreur : Vous devez être connecté pour envoyer un message."),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChatPage(
//           currentUser: currentUser,
//           otherUserId: widget.coiffeuse.uuid, // UUID de la coiffeuse
//         ),
//       ),
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, Colors.orange.shade50],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: CustomAppBar(
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 📸 Photo de profil
//               Center(
//                 child: CircleAvatar(
//                   radius: 60,
//                   backgroundImage: widget.coiffeuse.photoProfil != null &&
//                       widget.coiffeuse.photoProfil!.isNotEmpty
//                       ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                       : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // 📌 Nom & Dénomination
//               Center(
//                 child: Text(
//                   "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                   style: const TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 📋 Informations générales ExpansionTile
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpandedInfo,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpandedInfo = expanded;
//                     });
//                   },
//                   title: const Text(
//                     "Informations générales",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                   leading: Icon(
//                     isExpandedInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                     color: Colors.orange,
//                   ),
//                   children: [
//                     ListTile(
//                       title: Text(
//                         "📞 Téléphone : ${widget.coiffeuse.numeroTelephone ?? 'Non renseigné'}",
//                         style: const TextStyle(fontSize: 16, color: Colors.black54),
//                       ),
//                     ),
//                     ListTile(
//                       title: Text(
//                         "📧 Email : ${widget.coiffeuse.email ?? 'Non renseigné'}",
//                         style: const TextStyle(fontSize: 16, color: Colors.black54),
//                       ),
//                     ),
//                     ListTile(
//                       title: Text(
//                         "📍 Adresse : ${widget.coiffeuse.numero ?? ''} ${widget.coiffeuse.nomRue ?? ''}, ${widget.coiffeuse.commune ?? ''}, ${widget.coiffeuse.codePostal ?? ''}",
//                         style: const TextStyle(fontSize: 16, color: Colors.black54),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 💇‍♀️ Services sous forme de menu déroulant
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpandedServices,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpandedServices = expanded;
//                     });
//                   },
//                   title: const Text(
//                     "Services proposés",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                   leading: Icon(
//                     isExpandedServices ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                     color: Colors.orange,
//                   ),
//                   children: services.isEmpty
//                       ? [
//                     const Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: Text(
//                         "Aucun service disponible.",
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     )
//                   ]
//                       : services.map((service) {
//                     return Card(
//                       color: Colors.orange.shade50,
//                       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: ListTile(
//                         leading: const Icon(Icons.cut, color: Colors.orange),
//                         title: Text(
//                           service.intitule,
//                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
//                         ),
//                         subtitle: Text(
//                           "💰 ${service.prix}€  ⏳ ${service.temps} min",
//                           style: const TextStyle(color: Colors.black54),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Bouton "Contacter la coiffeuse"
//               Center(
//                 child: ElevatedButton.icon(
//                   onPressed: _contactCoiffeuse, // ✅ Appelle la nouvelle méthode ici
//                   icon: const Icon(Icons.message, color: Colors.white),
//                   label: const Text(
//                     "Contacter la coiffeuse",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//






























// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpandedInfo = false; // État pour l'ExpansionTile des infos générales
//   bool isExpandedServices = false; // État pour l'ExpansionTile des services
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, Colors.orange.shade50],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text(
//             "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon",
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Color(0xFFFF6F00),
//           elevation: 3,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 📸 Photo de profil
//               Center(
//                 child: CircleAvatar(
//                   radius: 60,
//                   backgroundImage: widget.coiffeuse.photoProfil != null &&
//                       widget.coiffeuse.photoProfil!.isNotEmpty
//                       ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                       : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // 📌 Nom & Dénomination
//               Center(
//                 child: Text(
//                   "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                   style: const TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 📋 Informations générales ExpansionTile
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpandedInfo,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpandedInfo = expanded;
//                     });
//                   },
//                   title: const Text(
//                     "Informations générales",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                   leading: Icon(
//                     isExpandedInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                     color: Colors.orange,
//                   ),
//                   children: [
//                     ListTile(
//                       title: Text(
//                         "📞 Téléphone : ${widget.coiffeuse.numeroTelephone ?? 'Non renseigné'}",
//                         style: const TextStyle(fontSize: 16, color: Colors.black54),
//                       ),
//                     ),
//                     ListTile(
//                       title: Text(
//                         "📧 Email : ${widget.coiffeuse.email ?? 'Non renseigné'}",
//                         style: const TextStyle(fontSize: 16, color: Colors.black54),
//                       ),
//                     ),
//                     ListTile(
//                       title: Text(
//                         "📍 Adresse : ${widget.coiffeuse.numero ?? ''} ${widget.coiffeuse.nomRue ?? ''}, ${widget.coiffeuse.commune ?? ''}, ${widget.coiffeuse.codePostal ?? ''}",
//                         style: const TextStyle(fontSize: 16, color: Colors.black54),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 💇‍♀️ Services sous forme de menu déroulant
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpandedServices,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpandedServices = expanded;
//                     });
//                   },
//                   title: const Text(
//                     "Services proposés",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                   leading: Icon(
//                     isExpandedServices ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                     color: Colors.orange,
//                   ),
//                   children: services.isEmpty
//                       ? [
//                     const Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: Text(
//                         "Aucun service disponible.",
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     )
//                   ]
//                       : services.map((service) {
//                     return Card(
//                       color: Colors.orange.shade50,
//                       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: ListTile(
//                         leading: const Icon(Icons.cut, color: Colors.orange),
//                         title: Text(
//                           service.intitule,
//                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
//                         ),
//                         subtitle: Text(
//                           "💰 ${service.prix}€  ⏳ ${service.temps} min",
//                           style: const TextStyle(color: Colors.black54),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//       ),
//     );
//   }
// }
































// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpanded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFFFEAC5E), // Orange
//             Color(0xFFC779D0), // Violet
//             Color(0xFF4BC0C8), // Turquoise
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text(
//             "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon",
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               shadows: [
//                 Shadow(
//                   blurRadius: 10.0,
//                   color: Colors.black,
//                   offset: Offset(2.0, 2.0),
//                 ),
//               ],
//             ),
//           ),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator(color: Colors.white))
//             : SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // 📸 Photo de profil avec ombre
//               Center(
//                 child: CircleAvatar(
//                   radius: 65,
//                   backgroundColor: Colors.white.withOpacity(0.3),
//                   child: CircleAvatar(
//                     radius: 60,
//                     backgroundImage: widget.coiffeuse.photoProfil != null &&
//                         widget.coiffeuse.photoProfil!.isNotEmpty
//                         ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                         : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 📌 Nom & Dénomination avec ombre
//               Center(
//                 child: Text(
//                   "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                   style: const TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     shadows: [
//                       Shadow(
//                         blurRadius: 5.0,
//                         color: Colors.black54,
//                         offset: Offset(2.0, 2.0),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     color: Colors.white70,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 💇‍♀️ Services sous forme de menu déroulant
//               Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpanded,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpanded = expanded;
//                     });
//                   },
//                   tilePadding: const EdgeInsets.symmetric(horizontal: 16),
//                   title: const Text(
//                     "Services proposés",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   childrenPadding: EdgeInsets.zero,
//                   children: services.isEmpty
//                       ? [
//                     const Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: Text(
//                         "Aucun service disponible.",
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     )
//                   ]
//                       : services.map((service) {
//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF333333),
//                         borderRadius: BorderRadius.circular(15),
//                         gradient: LinearGradient(
//                           colors: [
//                             const Color(0xFF2D3436), // Métallique
//                             const Color(0xFFC779D0), // Turquoise
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.all(16),
//                         leading: const Icon(Icons.cut, color: Colors.white),
//                         title: Text(
//                           service.intitule,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         subtitle: Text(
//                           "💰 ${service.prix}€  ⏳ ${service.temps} min",
//                           style: const TextStyle(color: Colors.white70),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpanded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   Color getTileColor(int index) {
//     List<Color> colors = [
//       const Color(0xFFFF0000), // Rouge vif
//       const Color(0xFFFFD700), // Doré métallique
//       const Color(0xFF212121), // Noir futuriste
//       const Color(0xFF00E5FF), // Bleu Arc Reactor
//     ];
//     return colors[index % colors.length];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF121212), Color(0xFF8B0000)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text(
//             "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon",
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Colors.redAccent,
//           elevation: 4,
//           shadowColor: Colors.black45,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
//             : SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 📸 Photo de profil (Effet Néon)
//               Center(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.redAccent.withOpacity(0.5),
//                         blurRadius: 20,
//                         spreadRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: CircleAvatar(
//                     radius: 60,
//                     backgroundColor: Color(0xFFFFD700),
//                     child: CircleAvatar(
//                       radius: 55,
//                       backgroundImage: widget.coiffeuse.photoProfil != null &&
//                           widget.coiffeuse.photoProfil!.isNotEmpty
//                           ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // 📌 Nom & Dénomination
//               Center(
//                 child: Text(
//                   "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     shadows: [
//                       Shadow(
//                         blurRadius: 10,
//                         color: Colors.redAccent,
//                         offset: Offset(2, 2),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                   style: const TextStyle(fontSize: 18, color: Color(0xFFFFD700)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 📍 Adresse
//               Row(
//                 children: [
//                   const Icon(Icons.location_on, color: Color(0xFF00E5FF)),
//                   const SizedBox(width: 5),
//                   Expanded(
//                     child: Text(
//                       "${widget.coiffeuse.numero ?? ''} "
//                           "${widget.coiffeuse.nomRue ?? ''}, "
//                           "${widget.coiffeuse.commune ?? ''}, "
//                           "${widget.coiffeuse.codePostal ?? ''}",
//                       style: TextStyle(color: Colors.white70, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//
//               // 💇‍♀️ Services sous forme de menu déroulant
//               Card(
//                 color: Color(0xFFB71C1C),
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Theme(
//                   data: Theme.of(context).copyWith(
//                     dividerColor: Colors.transparent, // Supprime les lignes entre les éléments
//                   ),
//                   child: ExpansionTile(
//                     initiallyExpanded: isExpanded,
//                     onExpansionChanged: (expanded) {
//                       setState(() {
//                         isExpanded = expanded;
//                       });
//                     },
//                     title: const Text(
//                       "Services proposés",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFFFFD700),
//                       ),
//                     ),
//                     leading: const Icon(Icons.cut, color: Color(0xFFFFD700)),
//                     children: services.isEmpty
//                         ? [
//                       const Padding(
//                         padding: EdgeInsets.all(10.0),
//                         child: Text("Aucun service disponible.", style: TextStyle(color: Colors.white70)),
//                       )
//                     ]
//                         : services.asMap().entries.map((entry) {
//                       int index = entry.key;
//                       Service service = entry.value;
//                       return Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                         decoration: BoxDecoration(
//                           color: getTileColor(index),
//                           borderRadius: BorderRadius.circular(15), // Coins arrondis
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.3),
//                               blurRadius: 6,
//                               offset: Offset(2, 2),
//                             )
//                           ],
//                         ),
//                         child: ListTile(
//                           leading: const Icon(Icons.flash_on, color: Color(0xFF00E5FF)),
//                           title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//                           subtitle: Text("💰 ${service.prix}€  ⏳ ${service.temps} min", style: const TextStyle(color: Colors.white70)),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpanded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   /// 📡 Récupérer les services de la coiffeuse
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   /// 🎨 Couleurs métalliques dynamiques
//   Color getTileColor(int index) {
//     List<Color> colors = [
//       const Color(0xFFFF0000), // Rouge vif
//       const Color(0xFFFFD700), // Doré métallique
//       const Color(0xFF212121), // Noir futuriste
//       const Color(0xFF00E5FF), // Bleu Arc Reactor
//     ];
//     return colors[index % colors.length];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF121212), Color(0xFF8B0000)], // Noir profond → Rouge foncé métallique
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text(
//             "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon",
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Colors.redAccent,
//           elevation: 4,
//           shadowColor: Colors.black45,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
//             : SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 📸 Photo de profil (Effet Néon)
//               Center(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.redAccent.withOpacity(0.5),
//                         blurRadius: 20,
//                         spreadRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: CircleAvatar(
//                     radius: 60,
//                     backgroundColor: Color(0xFFFFD700),
//                     child: CircleAvatar(
//                       radius: 55,
//                       backgroundImage: widget.coiffeuse.photoProfil != null &&
//                           widget.coiffeuse.photoProfil!.isNotEmpty
//                           ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // 📌 Nom & Dénomination
//               Center(
//                 child: Text(
//                   "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     shadows: [
//                       Shadow(
//                         blurRadius: 10,
//                         color: Colors.redAccent,
//                         offset: Offset(2, 2),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                   style: const TextStyle(fontSize: 18, color: Color(0xFFFFD700)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 📍 Adresse
//               Row(
//                 children: [
//                   const Icon(Icons.location_on, color: Color(0xFF00E5FF)),
//                   const SizedBox(width: 5),
//                   Expanded(
//                     child: Text(
//                       "${widget.coiffeuse.numero ?? ''} "
//                           "${widget.coiffeuse.nomRue ?? ''}, "
//                           "${widget.coiffeuse.commune ?? ''}, "
//                           "${widget.coiffeuse.codePostal ?? ''}",
//                       style: TextStyle(color: Colors.white70, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//
//               // 💇‍♀️ Services sous forme de menu déroulant
//               Card(
//                 color: Color(0xFFB71C1C), // Rouge métallisé
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpanded,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpanded = expanded;
//                     });
//                   },
//                   title: const Text(
//                     "Services proposés",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFFFFD700),
//                     ),
//                   ),
//                   leading: const Icon(Icons.cut, color: Color(0xFFFFD700)),
//                   children: services.isEmpty
//                       ? [
//                     const Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: Text("Aucun service disponible.", style: TextStyle(color: Colors.white70)),
//                     )
//                   ]
//                       : services.asMap().entries.map((entry) {
//                     int index = entry.key;
//                     Service service = entry.value;
//                     return Card(
//                       color: getTileColor(index),
//                       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: ListTile(
//                         tileColor: getTileColor(index),
//                         leading: const Icon(Icons.flash_on, color: Color(0xFF00E5FF)),
//                         title: Text(service.intitule, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//                         subtitle: Text("💰 ${service.prix}€  ⏳ ${service.temps} min", style: const TextStyle(color: Colors.white70)),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpanded = false; // État du menu déroulant
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   /// 📡 Récupérer les services de la coiffeuse
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   /// 🎨 Fonction pour générer une couleur unique pour chaque ListTile
//   Color getTileColor(int index) {
//     List<Color> colors = [
//       Colors.orange.shade100,
//       Colors.blue.shade100,
//       Colors.green.shade100,
//       Colors.purple.shade100,
//       Colors.pink.shade100,
//       Colors.teal.shade100
//     ];
//     return colors[index % colors.length]; // Sélectionne une couleur en fonction de l'index
//   }
//
//   /// 🎨 Fonction pour générer une couleur unique pour l'arrière-plan de la carte ListTile
//   Color getCardColor(int index) {
//     List<Color> colors = [
//       Colors.purple.shade300,
//       Colors.pink.shade300,
//       Colors.teal.shade300,
//       Colors.orange.shade300,
//       Colors.blue.shade300,
//       Colors.green.shade300
//     ];
//     return colors[index % colors.length];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.white, Colors.orange.shade50], // Dégradé subtil
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent, // Fond transparent pour voir le gradient
//         appBar: AppBar(
//           title: Text(
//             "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon",
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Color(0xFFFF6F00),
//           elevation: 3,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 📸 Photo de profil
//               Center(
//                 child: CircleAvatar(
//                   radius: 60,
//                   backgroundImage: widget.coiffeuse.photoProfil != null &&
//                       widget.coiffeuse.photoProfil!.isNotEmpty
//                       ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                       : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // 📌 Nom & Dénomination
//               Center(
//                 child: Text(
//                   "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                   style: const TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // 📍 Adresse
//               Row(
//                 children: [
//                   const Icon(Icons.location_on, color: Colors.red),
//                   const SizedBox(width: 5),
//                   Expanded(
//                     child: Text(
//                       "${widget.coiffeuse.numero ?? ''} "
//                           "${widget.coiffeuse.nomRue ?? ''}, "
//                           "${widget.coiffeuse.commune ?? ''}, "
//                           "${widget.coiffeuse.codePostal ?? ''}",
//                       style: TextStyle(color: Colors.black87, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//
//               // 💇‍♀️ Services sous forme de menu déroulant
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ExpansionTile(
//                   initiallyExpanded: isExpanded,
//                   onExpansionChanged: (expanded) {
//                     setState(() {
//                       isExpanded = expanded;
//                     });
//                   },
//                   title: const Text(
//                     "Services proposés",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                   leading: Icon(
//                     isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                     color: Colors.orange,
//                   ),
//                   children: services.isEmpty
//                       ? [
//                     const Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: Text("Aucun service disponible.", style: TextStyle(color: Colors.black54)),
//                     )
//                   ]
//                       : services.asMap().entries.map((entry) {
//                     int index = entry.key;
//                     Service service = entry.value;
//                     return Card(
//                       color: getCardColor(index),
//                       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: ListTile(
//                         tileColor: getTileColor(index),
//                         leading: const Icon(Icons.cut, color: Colors.white),
//                         title: Text(
//                           service.intitule,
//                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//                         ),
//                         subtitle: Text(
//                           "💰 ${service.prix}€  ⏳ ${service.temps} min",
//                           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpanded = false; // État du menu déroulant
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   /// 📡 Récupérer les services de la coiffeuse
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF5F5F5), // Fond gris clair
//       appBar: AppBar(
//         title: Text("${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon"),
//         backgroundColor: Color(0xFFFF6F00), // Orange vif
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 📸 Photo de profil
//             Center(
//               child: CircleAvatar(
//                 radius: 60,
//                 backgroundImage: widget.coiffeuse.photoProfil != null &&
//                     widget.coiffeuse.photoProfil!.isNotEmpty
//                     ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                     : const AssetImage('assets/default_avatar.png') as ImageProvider,
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             // 📌 Nom & Dénomination
//             Center(
//               child: Text(
//                 "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
//               ),
//             ),
//             Center(
//               child: Text(
//                 widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                 style: const TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             // 📍 Adresse
//             Row(
//               children: [
//                 const Icon(Icons.location_on, color: Colors.red),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   child: Text(
//                     "${widget.coiffeuse.numero ?? ''} "
//                         "${widget.coiffeuse.nomRue ?? ''}, "
//                         "${widget.coiffeuse.commune ?? ''}, "
//                         "${widget.coiffeuse.codePostal ?? ''}",
//                     style: TextStyle(color: Colors.black87, fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//
//             // 📜 TVA
//             Row(
//               children: [
//                 const Icon(Icons.business, color: Colors.orange),
//                 const SizedBox(width: 5),
//                 Text(
//                   "TVA : ${widget.coiffeuse.tva ?? 'Non renseignée'}",
//                   style: TextStyle(fontSize: 16, color: Colors.black87),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             // 💇‍♀️ Services sous forme de menu déroulant
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ExpansionTile(
//                 initiallyExpanded: isExpanded,
//                 onExpansionChanged: (expanded) {
//                   setState(() {
//                     isExpanded = expanded;
//                   });
//                 },
//                 title: const Text(
//                   "Services proposés",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                 ),
//                 leading: Icon(
//                   isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                   color: Colors.orange,
//                 ),
//                 children: services.isEmpty
//                     ? [
//                   const Padding(
//                     padding: EdgeInsets.all(10.0),
//                     child: Text("Aucun service disponible.", style: TextStyle(color: Colors.black54)),
//                   )
//                 ]
//                     : services.map((service) {
//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: ListTile(
//                       leading: const Icon(Icons.cut, color: Colors.orange),
//                       title: Text(
//                         service.intitule,
//                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
//                       ),
//                       subtitle: Text(
//                         "💰 ${service.prix}€  ⏳ ${service.temps} min",
//                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/Services.dart';
// import 'package:hairbnb/models/coiffeuse.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class SalonCoiffeusePage extends StatefulWidget {
//   final Coiffeuse coiffeuse;
//
//   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
//
//   @override
//   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// }
//
// class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
//   List<Service> services = [];
//   bool isLoading = true;
//   bool isExpanded = false; // État du menu déroulant
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchServices();
//   }
//
//   /// 📡 Récupérer les services de la coiffeuse
//   Future<void> _fetchServices() async {
//     final String apiUrl =
//         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         Map<String, dynamic> responseData = json.decode(decodedBody);
//
//         if (responseData['status'] == 'success' && responseData['salon'] != null) {
//           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
//           setState(() {
//             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon")),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 📸 Photo de profil
//             Center(
//               child: CircleAvatar(
//                 radius: 60,
//                 backgroundImage: widget.coiffeuse.photoProfil != null &&
//                     widget.coiffeuse.photoProfil!.isNotEmpty
//                     ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
//                     : const AssetImage('assets/default_avatar.png') as ImageProvider,
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             // 📌 Nom & Dénomination
//             Center(
//               child: Text(
//                 "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
//                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//             ),
//             Center(
//               child: Text(
//                 widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
//                 style: const TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             // 📍 Adresse
//             Row(
//               children: [
//                 const Icon(Icons.location_on, color: Colors.red),
//                 const SizedBox(width: 5),
//                 Expanded(
//                   child: Text(
//                     "${widget.coiffeuse.numero ?? ''} "
//                         "${widget.coiffeuse.nomRue ?? ''}, "
//                         "${widget.coiffeuse.commune ?? ''}, "
//                         "${widget.coiffeuse.codePostal ?? ''}",
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//
//             // 📜 TVA
//             Row(
//               children: [
//                 const Icon(Icons.business, color: Colors.orange),
//                 const SizedBox(width: 5),
//                 Text("TVA : ${widget.coiffeuse.tva ?? 'Non renseignée'}"),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             // 💇‍♀️ Menu déroulant pour les services
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: ExpansionTile(
//                 initiallyExpanded: isExpanded,
//                 onExpansionChanged: (expanded) {
//                   setState(() {
//                     isExpanded = expanded;
//                   });
//                 },
//                 title: Text(
//                   "Services",
//                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 leading: Icon(
//                   isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                   color: Colors.orange,
//                 ),
//                 children: services.isEmpty
//                     ? [
//                   const Padding(
//                     padding: EdgeInsets.all(10.0),
//                     child: Text("Aucun service disponible."),
//                   )
//                 ]
//                     : services.map((service) {
//                   return ListTile(
//                     leading: const Icon(Icons.cut, color: Colors.orange),
//                     title: Text(service.intitule),
//                     subtitle: Text("${service.prix}€ - ${service.temps} min"),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:hairbnb/models/Services.dart';
// // import 'package:hairbnb/models/coiffeuse.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class SalonCoiffeusePage extends StatefulWidget {
// //   final Coiffeuse coiffeuse;
// //
// //   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
// //
// //   @override
// //   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// // }
// //
// // class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
// //   List<Service> services = [];
// //   bool isLoading = true;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchServices();
// //   }
// //
// //   /// 📡 Récupérer les services de la coiffeuse
// //   Future<void> _fetchServices() async {
// //     final String apiUrl =
// //         'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
// //
// //     print("🔍 Requête API : $apiUrl");
// //
// //     try {
// //       final response = await http.get(Uri.parse(apiUrl));
// //       print("📡 Réponse API (Code ${response.statusCode}): ${response.body}");
// //
// //       if (response.statusCode == 200) {
// //         final decodedBody = utf8.decode(response.bodyBytes);
// //         Map<String, dynamic> responseData = json.decode(decodedBody);
// //
// //         if (responseData['status'] == 'success' && responseData['salon'] != null) {
// //           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
// //
// //           print("✅ Services reçus : $serviceList");
// //
// //           setState(() {
// //             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
// //             isLoading = false;
// //           });
// //
// //           if (services.isEmpty) {
// //             print("⚠️ Aucun service trouvé.");
// //           }
// //         } else {
// //           print("❌ Erreur : Données incorrectes");
// //           setState(() => isLoading = false);
// //         }
// //       } else {
// //         print("❌ Erreur API : ${response.statusCode}");
// //         setState(() => isLoading = false);
// //       }
// //     } catch (e) {
// //       print("🚨 Erreur réseau : $e");
// //       setState(() => isLoading = false);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text("${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon")),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // 📸 Photo de profil
// //             Center(
// //               child: CircleAvatar(
// //                 radius: 60,
// //                 backgroundImage: widget.coiffeuse.photoProfil != null &&
// //                     widget.coiffeuse.photoProfil!.isNotEmpty
// //                     ? NetworkImage('http://192.168.0.248:8000${widget.coiffeuse.photoProfil}')
// //                     : const AssetImage('assets/default_avatar.png') as ImageProvider,
// //               ),
// //             ),
// //             const SizedBox(height: 10),
// //
// //             // 📌 Nom & Dénomination
// //             Center(
// //               child: Text(
// //                 "${widget.coiffeuse.nom} ${widget.coiffeuse.prenom}",
// //                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
// //               ),
// //             ),
// //             Center(
// //               child: Text(
// //                 widget.coiffeuse.denominationSociale ?? "Dénomination inconnue",
// //                 style: const TextStyle(fontSize: 18, color: Colors.grey),
// //               ),
// //             ),
// //             const SizedBox(height: 10),
// //
// //             // 📍 Adresse
// //             Row(
// //               children: [
// //                 const Icon(Icons.location_on, color: Colors.red),
// //                 const SizedBox(width: 5),
// //                 Expanded(
// //                   child: Text(
// //                     "${widget.coiffeuse.numero ?? ''} "
// //                         "${widget.coiffeuse.nomRue ?? ''}, "
// //                         "${widget.coiffeuse.commune ?? ''}, "
// //                         "${widget.coiffeuse.codePostal ?? ''}",
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //
// //             // 📜 TVA
// //             Row(
// //               children: [
// //                 const Icon(Icons.business, color: Colors.orange),
// //                 const SizedBox(width: 5),
// //                 Text("TVA : ${widget.coiffeuse.tva ?? 'Non renseignée'}"),
// //               ],
// //             ),
// //             const SizedBox(height: 20),
// //
// //             // 💇‍♀️ Liste des services
// //             const Text(
// //               "Services proposés :",
// //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //             ),
// //             const SizedBox(height: 10),
// //             services.isEmpty
// //                 ? const Center(child: Text("Aucun service disponible."))
// //                 : Column(
// //               children: services.map((service) {
// //                 return Card(
// //                   margin: const EdgeInsets.symmetric(vertical: 5),
// //                   child: ListTile(
// //                     leading: const Icon(Icons.cut, color: Colors.orange),
// //                     title: Text(service.intitule),
// //                     subtitle: Text("${service.prix}€ - ${service.temps} min"),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // import 'package:flutter/material.dart';
// // // import 'package:hairbnb/models/Services.dart';
// // // import 'package:hairbnb/models/coiffeuse.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'dart:convert';
// // //
// // // class SalonCoiffeusePage extends StatefulWidget {
// // //   final Coiffeuse coiffeuse;
// // //
// // //   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
// // //
// // //   @override
// // //   _SalonCoiffeusePageState createState() => _SalonCoiffeusePageState();
// // // }
// // //
// // // class _SalonCoiffeusePageState extends State<SalonCoiffeusePage> {
// // //   List<Service> services = [];
// // //   bool isLoading = true;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchServices();
// // //   }
// // //
// // //   /// 📡 Récupérer les services de la coiffeuse
// // //   Future<void> _fetchServices() async {
// // //     final String apiUrl = 'http://192.168.0.248:8000/api/get_services_by_coiffeuse/${widget.coiffeuse.idTblUser}/';
// // //
// // //     print("🔍 Requête API : $apiUrl");
// // //
// // //     try {
// // //       final response = await http.get(Uri.parse(apiUrl));
// // //       print("📡 Réponse API (Code ${response.statusCode}): ${response.body}");
// // //
// // //       if (response.statusCode == 200) {
// // //         Map<String, dynamic> responseData = json.decode(response.body);
// // //
// // //         if (responseData['status'] == 'success' && responseData['salon'] != null) {
// // //           List<dynamic> serviceList = responseData['salon']['services'] ?? [];
// // //
// // //           print("✅ Services reçus : $serviceList");
// // //
// // //           setState(() {
// // //             services = serviceList.map((serviceJson) => Service.fromJson(serviceJson)).toList();
// // //             isLoading = false;
// // //           });
// // //
// // //           if (services.isEmpty) {
// // //             print("⚠️ Aucun service trouvé.");
// // //           }
// // //         } else {
// // //           print("❌ Erreur : Données incorrectes");
// // //           setState(() => isLoading = false);
// // //         }
// // //       } else {
// // //         print("❌ Erreur API : ${response.statusCode}");
// // //         setState(() => isLoading = false);
// // //       }
// // //     } catch (e) {
// // //       print("🚨 Erreur réseau : $e");
// // //       setState(() => isLoading = false);
// // //     }
// // //   }
// // //
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: Text("${widget.coiffeuse.nom} ${widget.coiffeuse.prenom} - Salon")),
// // //       body: isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : ListView.builder(
// // //         itemCount: services.length,
// // //         itemBuilder: (context, index) {
// // //           final service = services[index];
// // //           return ListTile(
// // //             title: Text(service.intitule),
// // //             subtitle: Text("${service.prix}€ - ${service.temps} min"),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // // // import 'package:flutter/material.dart';
// // // // import 'package:hairbnb/models/coiffeuse.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'dart:convert'; // Assurez-vous que ce fichier contient la classe Coiffeuse
// // // //
// // // // class ProfileScreen extends StatefulWidget {
// // // //   final String userUuid;
// // // //   final bool isCoiffeuse;
// // // //
// // // //   const ProfileScreen({Key? key, required this.userUuid, required this.isCoiffeuse}) : super(key: key);
// // // //
// // // //   @override
// // // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // // }
// // // //
// // // // class _ProfileScreenState extends State<ProfileScreen> {
// // // //   Coiffeuse? coiffeuse;
// // // //   bool isLoading = true;
// // // //   String errorMessage = "";
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchUserProfile();
// // // //   }
// // // //
// // // //   /// 🔍 **Récupérer les données du profil depuis l'API**
// // // //   Future<void> fetchUserProfile() async {
// // // //     final String baseUrl = 'http://192.168.0.248:8000/api/get_user_profile/${widget.userUuid}/';
// // // //
// // // //     try {
// // // //       final response = await http.get(Uri.parse(baseUrl));
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         final data = json.decode(response.body);
// // // //         setState(() {
// // // //           coiffeuse = Coiffeuse.fromJson(data['data']);
// // // //           isLoading = false;
// // // //         });
// // // //       } else {
// // // //         setState(() {
// // // //           errorMessage = "Erreur : ${response.statusCode} ${response.reasonPhrase}";
// // // //           isLoading = false;
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         errorMessage = "Erreur réseau : $e";
// // // //         isLoading = false;
// // // //       });
// // // //     }
// // // //   }
// // // //
// // // //   /// 🔥 **Mise à jour d'un champ utilisateur**
// // // //   Future<void> updateUserProfile(String fieldName, String newValue) async {
// // // //     final String apiUrl = 'http://192.168.0.248:8000/api/update_user_profile/${widget.userUuid}/';
// // // //     try {
// // // //       final response = await http.patch(
// // // //         Uri.parse(apiUrl),
// // // //         headers: {'Content-Type': 'application/json'},
// // // //         body: jsonEncode({fieldName: newValue}),
// // // //       );
// // // //
// // // //       if (response.statusCode == 200) {
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           const SnackBar(content: Text("Profil mis à jour avec succès"), backgroundColor: Colors.green),
// // // //         );
// // // //         fetchUserProfile();  // 🔄 Rafraîchir les données après modification
// // // //       } else {
// // // //         throw Exception("Erreur serveur : ${response.statusCode}");
// // // //       }
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text("Erreur réseau : $e"), backgroundColor: Colors.red),
// // // //       );
// // // //     }
// // // //   }
// // // //
// // // //   /// 📝 **Modifier un champ**
// // // //   void _editField(String fieldName, String currentValue) {
// // // //     final TextEditingController fieldController = TextEditingController(text: currentValue);
// // // //
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (context) {
// // // //         return AlertDialog(
// // // //           title: Text("Modifier $fieldName"),
// // // //           content: TextField(
// // // //             controller: fieldController,
// // // //             decoration: InputDecoration(hintText: "Nouvelle valeur pour $fieldName"),
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(context),
// // // //               child: const Text("Annuler"),
// // // //             ),
// // // //             TextButton(
// // // //               onPressed: () async {
// // // //                 Navigator.pop(context);
// // // //                 if (fieldController.text.isNotEmpty && fieldController.text != currentValue) {
// // // //                   await updateUserProfile(fieldName, fieldController.text);
// // // //                 }
// // // //               },
// // // //               child: const Text("Sauvegarder"),
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   /// **🖼 Affichage de l'image de profil**
// // // //   Widget _buildProfileImage() {
// // // //     String? imageUrl = coiffeuse?.photoProfil;
// // // //     return CircleAvatar(
// // // //       radius: 60,
// // // //       backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
// // // //           ? NetworkImage('http://192.168.0.248:8000$imageUrl')
// // // //           : const AssetImage('assets/default_avatar.png') as ImageProvider,
// // // //       onBackgroundImageError: (exception, stackTrace) {
// // // //         print("Erreur de chargement de l'image : $exception");
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   /// **📝 Générer une ligne d'information**
// // // //   Widget _infoTile(IconData icon, String label, dynamic value) {
// // // //     return ListTile(
// // // //       leading: Icon(icon),
// // // //       title: Text(value != null && value.toString().isNotEmpty ? value.toString() : "Non spécifié"),
// // // //       trailing: IconButton(
// // // //         icon: const Icon(Icons.edit),
// // // //         onPressed: () => _editField(label, value ?? ""),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   /// **🏠 Construire la page de profil**
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text("Profil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// // // //       ),
// // // //       body: isLoading
// // // //           ? const Center(child: CircularProgressIndicator())
// // // //           : errorMessage.isNotEmpty
// // // //           ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
// // // //           : coiffeuse == null
// // // //           ? const Center(child: Text("Aucune donnée à afficher."))
// // // //           : SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Column(
// // // //           children: [
// // // //             // 🔹 Image de profil
// // // //             _buildProfileImage(),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 🔹 Nom et Type
// // // //             Text("${coiffeuse!.prenom} ${coiffeuse!.nom}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// // // //             const SizedBox(height: 5),
// // // //             Text("Type : Coiffeuse", style: const TextStyle(fontSize: 16)),
// // // //             const SizedBox(height: 20),
// // // //
// // // //             const Divider(),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 🔹 Informations générales
// // // //             _infoTile(Icons.email, "Email", coiffeuse!.email),
// // // //             _infoTile(Icons.phone, "Téléphone", coiffeuse!.numeroTelephone),
// // // //
// // // //             // 🔹 Adresse
// // // //             if (coiffeuse!.nomRue != null) _infoTile(Icons.location_on, "Rue", coiffeuse!.nomRue),
// // // //             if (coiffeuse!.commune != null) _infoTile(Icons.location_city, "Commune", coiffeuse!.commune),
// // // //             if (coiffeuse!.codePostal != null) _infoTile(Icons.local_post_office, "Code postal", coiffeuse!.codePostal),
// // // //
// // // //             const Divider(),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 🔹 Informations professionnelles (si applicable)
// // // //             if (widget.isCoiffeuse) ...[
// // // //               _infoTile(Icons.business, "Dénomination Sociale", coiffeuse!.denominationSociale),
// // // //               _infoTile(Icons.money, "TVA", coiffeuse!.tva),
// // // //               _infoTile(Icons.map, "Position", coiffeuse!.position),
// // // //             ],
// // // //
// // // //             const Divider(),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 🔹 Bouton Services
// // // //             _infoTile(Icons.build, "Services", "Voir Services"),
// // // //
// // // //             // 🔹 Bouton Déconnexion
// // // //             _infoTile(Icons.logout, "Déconnexion", ""),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // // //
// // //
// // //
// // //
// // //
// // // // import 'package:flutter/material.dart';
// // // //
// // // // class SalonCoiffeusePage extends StatelessWidget {
// // // //   final Map<String, dynamic> coiffeuse;
// // // //
// // // //   const SalonCoiffeusePage({Key? key, required this.coiffeuse}) : super(key: key);
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     // Récupération des données
// // // //     String nom = coiffeuse['user']['nom'] ?? "Inconnu";
// // // //     String prenom = coiffeuse['user']['prenom'] ?? "";
// // // //     String photoProfil = coiffeuse['user']['photo_profil'] ??
// // // //         'https://via.placeholder.com/150';
// // // //     String denominationSociale = coiffeuse['denomination_sociale'] ?? "Non spécifié";
// // // //     String tva = coiffeuse['tva'] ?? "Non renseignée";
// // // //     List<dynamic> services = coiffeuse['services'] ?? [];
// // // //     String adresse = "${coiffeuse['user']['adresse']['numero'] ?? ''}, "
// // // //         "${coiffeuse['user']['adresse']['rue']['nom_rue'] ?? ''}, "
// // // //         "${coiffeuse['user']['adresse']['rue']['localite']['commune'] ?? ''}";
// // // //
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Text("$nom $prenom - Salon"),
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Column(
// // // //           crossAxisAlignment: CrossAxisAlignment.start,
// // // //           children: [
// // // //             // 📸 Photo de profil
// // // //             Center(
// // // //               child: CircleAvatar(
// // // //                 radius: 50,
// // // //                 backgroundImage: NetworkImage('http://192.168.0.248:8000'+photoProfil),
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 📌 Nom & Dénomination
// // // //             Center(
// // // //               child: Text(
// // // //                 "$nom $prenom",
// // // //                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// // // //               ),
// // // //             ),
// // // //             Center(
// // // //               child: Text(
// // // //                 denominationSociale,
// // // //                 style: const TextStyle(fontSize: 16, color: Colors.grey),
// // // //               ),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 🏡 Adresse
// // // //             Row(
// // // //               children: [
// // // //                 const Icon(Icons.location_on, color: Colors.red),
// // // //                 const SizedBox(width: 5),
// // // //                 Expanded(child: Text(adresse)),
// // // //               ],
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //
// // // //             // 📜 TVA
// // // //             Row(
// // // //               children: [
// // // //                 const Icon(Icons.business, color: Colors.orange),
// // // //                 const SizedBox(width: 5),
// // // //                 Text("TVA : $tva"),
// // // //               ],
// // // //             ),
// // // //             const SizedBox(height: 20),
// // // //
// // // //             // 💇‍♀️ Liste des services
// // // //             const Text(
// // // //               "Services proposés :",
// // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // //             ),
// // // //             const SizedBox(height: 10),
// // // //             services.isEmpty
// // // //                 ? const Text("Aucun service disponible.")
// // // //                 : Column(
// // // //               children: services.map((service) {
// // // //                 return Card(
// // // //                   margin: const EdgeInsets.symmetric(vertical: 5),
// // // //                   child: ListTile(
// // // //                     leading: const Icon(Icons.cut, color: Colors.orange),
// // // //                     title: Text(service['intitule'] ?? "Service"),
// // // //                     subtitle: Text("${service['prix']}€ - ${service['temps']} min"),
// // // //                   ),
// // // //                 );
// // // //               }).toList(),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
