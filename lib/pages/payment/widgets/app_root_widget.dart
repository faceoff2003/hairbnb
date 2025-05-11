// import 'package:flutter/material.dart';
// import 'package:hairbnb/pages/splash_screen.dart';
// import 'package:hairbnb/pages/paiement_success_page.dart'; // Créez ce fichier
// import 'package:hairbnb/pages/paiement_error_page.dart'; // Créez ce fichier
// import 'package:hairbnb/services/deep_link_handler.dart';
//
// import '../payment_services/deep_link_handler_service.dart';
//
// class AppRoot extends StatefulWidget {
//   const AppRoot({super.key});
//
//   @override
//   State<AppRoot> createState() => _AppRootState();
// }
//
// class _AppRootState extends State<AppRoot> {
//   @override
//   void initState() {
//     super.initState();
//     // Initialiser après le premier rendu
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       DeepLinkHandler.initDeepLinks(context);
//     });
//   }
//
//   @override
//   void dispose() {
//     DeepLinkHandler.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hairbnb app',
//       theme: ThemeData(primarySwatch: Colors.deepPurple),
//       home: const SplashScreen(),
//       debugShowCheckedModeBanner: false,
//       routes: {
//         '/success-page': (context) => const PaiementSuccessPage(),
//         '/error-page': (context) => const PaiementErrorPage(),
//       },
//     );
//   }
// }