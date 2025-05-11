// import 'package:flutter/foundation.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
//
// class WebUrlService {
//   // Singleton pattern
//   static final WebUrlService _instance = WebUrlService._internal();
//   factory WebUrlService() => _instance;
//   WebUrlService._internal();
//
//   bool _initialized = false;
//
//   // Cette méthode ne fait quelque chose que sur le web
//   void configureWebUrlStrategy() {
//     // Vérifie si nous sommes sur le web et si ce n'est pas déjà initialisé
//     if (kIsWeb && !_initialized) {
//       setUrlStrategy(const HashUrlStrategy());
//       _initialized = true;
//       print('Configuration des URLs web initialisée');
//     }
//   }
// }
//
//
//
// // import 'dart:ui_web';
// //
// // import 'package:flutter/foundation.dart';
// //
// // class WebUrlService {
// //   // Singleton pattern
// //   static final WebUrlService _instance = WebUrlService._internal();
// //   factory WebUrlService() => _instance;
// //   WebUrlService._internal();
// //
// //   bool _initialized = false;
// //
// //   // Cette méthode ne fait quelque chose que sur le web
// //   void configureWebUrlStrategy() {
// //     // Vérifie si nous sommes sur le web et si ce n'est pas déjà initialisé
// //     if (kIsWeb && !_initialized) {
// //       setUrlStrategy(const HashUrlStrategy());
// //       _initialized = true;
// //       print('Configuration des URLs web initialisée');
// //     }
// //   }
// // }