// import 'package:http/http.dart' as http;
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class AuthenticatedHttpClient extends http.BaseClient {
//   final http.Client _inner = http.Client();
//
//   @override
//   Future<http.StreamedResponse> send(http.BaseRequest request) async {
//     // Obtenir le token actuel
//     String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
//
//     if (token != null) {
//       request.headers['Authorization'] = 'Bearer $token';
//     }
//
//     return _inner.send(request);
//   }
// }