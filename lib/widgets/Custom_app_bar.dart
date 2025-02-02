import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/providers/current_user_provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});
  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CurrentUserProvider>(context, listen: false).fetchCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
    final String baseUrl = "http://192.168.0.248:8000/";

    return AppBar(
      title: Row(
        children: [
          if (currentUser?.photoProfil != null)
            CircleAvatar(
              backgroundImage: NetworkImage(baseUrl+currentUser!.photoProfil!),
              radius: 20,
            )
          else
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 20,
              child: Icon(Icons.person, color: Colors.white),
            ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18, color: Colors.black),
              children: [
                TextSpan(
                  text: currentUser != null
                      ? "${currentUser.nom} ${currentUser.prenom} "
                      : "Chargement...",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: currentUser != null ? "(${currentUser.type})" : "",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange,
    );
  }
}















// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
//
//
// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   const CustomAppBar({Key? key}) : super(key: key);
//
//   final String baseUrl = "http://192.168.0.248:8000";
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = Provider.of<CurrentUserProvider>(context).currentUser;
//
//     return AppBar(
//       title: Row(
//         children: [
//           if (currentUser?.photoProfil?.isNotEmpty ?? false)
//             CircleAvatar(
//               backgroundImage: NetworkImage(baseUrl+currentUser!.photoProfil!),
//               radius: 20,
//             )
//           else
//             const CircleAvatar(
//               backgroundColor: Colors.grey,
//               radius: 20,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//           const SizedBox(width: 10),
//           Text(
//             currentUser != null
//                 ? "${currentUser.nom} ${currentUser.prenom} (${currentUser.type})"
//                 : "Chargement...",
//           ),
//         ],
//       ),
//       backgroundColor: Colors.orange,
//     );
//   }
//
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:hairbnb/models/current_user.dart';
// //
// // class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
// //   final Function(CurrentUser?) onUserLoaded;
// //
// //   const CustomAppBar({Key? key, required this.onUserLoaded}) : super(key: key);
// //
// //   @override
// //   _CustomAppBarState createState() => _CustomAppBarState();
// //
// //   @override
// //   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// // }
// //
// // class _CustomAppBarState extends State<CustomAppBar> {
// //   CurrentUser? currentUser;
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final String baseUrl = "http://192.168.0.248:8000";
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchCurrentUser();
// //   }
// //
// //   Future<void> _fetchCurrentUser() async {
// //     try {
// //       User? firebaseUser = _auth.currentUser;
// //       if (firebaseUser == null) {
// //         widget.onUserLoaded(null);
// //         return;
// //       }
// //
// //       String firebaseUid = firebaseUser.uid;
// //       final response = await http.get(
// //         Uri.parse('$baseUrl/api/get_current_user/$firebaseUid/'),
// //         headers: {'Content-Type': 'application/json'},
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         setState(() {
// //           currentUser = CurrentUser.fromJson(data['user']);
// //         });
// //
// //         widget.onUserLoaded(currentUser);
// //       } else {
// //         widget.onUserLoaded(null);
// //       }
// //     } catch (error) {
// //       widget.onUserLoaded(null);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return AppBar(
// //       title: Row(
// //         children: [
// //           if (currentUser?.photoProfil?.isNotEmpty ?? false)
// //             CircleAvatar(
// //               backgroundImage: NetworkImage(baseUrl+'/'+currentUser!.photoProfil!),
// //               radius: 20,
// //             )
// //           else
// //             const CircleAvatar(
// //               backgroundColor: Colors.grey,
// //               radius: 20,
// //               child: Icon(Icons.person, color: Colors.white),
// //             ),
// //           const SizedBox(width: 10),
// //           Text(currentUser != null ? "${currentUser!.nom} ${currentUser!.prenom} (${currentUser!.type})" : "Chargement..."),
// //         ],
// //       ),
// //       backgroundColor: Colors.orange,
// //     );
// //   }
// // }