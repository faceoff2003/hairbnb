import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:hairbnb/pages/ai_chat/services/ai_chat_service.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/services/providers/cart_provider.dart';
import 'package:hairbnb/services/providers/disponibilites_provider.dart';
import 'package:hairbnb/services/routes_services/route_service.dart';
import 'firebase_options.dart';
import 'package:hairbnb/pages/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/providers/current_user_provider.dart';



class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // if (kIsWeb) {
  //   // Configurer l'URL strategy pour le web uniquement
  //   WebUrlService().configureWebUrlStrategy();
  // }


 //  if (!kIsWeb) {
 //    // 🔐 Initialisation Stripe
 //    Stripe.publishableKey =
 //    "pk_test_51QxTcwPLEsfXjeyfbxYM0qSVUfouAqtUGbVOTXmf3fr3y6tBtX5aylUzP3xLPniIXWu7hmuBGdvIWJ6fueZZe70d00dn2sPdfv";
 //    Stripe.merchantIdentifier = 'hairbnb_merchant';
 //    Stripe.urlScheme = 'hairbnb';
 //
 //  await Stripe.instance.applySettings();
 // }

  if (kIsWeb) {
    // setUrlStrategy(PathUrlStrategy());
    // print('✅ Configuration Web effectuée');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBwQnw-rxiMy88yqf-rWUxIuWLTSfiTkEc",
        authDomain: "hairbnb-7eeb9.firebaseapp.com",
        databaseURL: "https://hairbnb-7eeb9-default-rtdb.europe-west1.firebasedatabase.app",
        projectId: "hairbnb-7eeb9",
        storageBucket: "hairbnb-7eeb9.firebasestorage.app",
        messagingSenderId: "523426514457",
        appId: "1:523426514457:web:c12474ba6a3bed7ef08c88",
        measurementId: "G-E9GTDH2YCN"
      ),
    );
  } else {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );}

  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrentUserProvider()), // 🔥 Initialisation de `UserProvider
        ChangeNotifierProvider(create: (context) => CartProvider()),//
        ChangeNotifierProvider(create: (_) => DisponibilitesProvider()),
        ChangeNotifierProvider(create: (context) => AIChatProvider(AIChatService(
              baseUrl: 'https://www.hairbnb.site/api',
              token: '', // Vous pouvez initialiser avec une chaîne vide et mettre à jour plus tard
            ),
          ),
        ),
      ],
      //child: const AppRoot(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hairbnb app',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      //home:  const LoginPage(),
      home: const SplashScreen(), // Utilisation de SplashScreen
      //home: const CreateServicesPage(),
      //home: const CreateSalonPage(userUuid: 'xxx',),
      //home: const ChatsScreen(),
      //home: const ProfileCreationPage(),
      //home : const OSMTestPage(),
      //home:const ServicesListPage(coiffeuseId: 'coiffeuseId',),
      //home: SearchCoiffeusePage(),
      //home: ChatPage(clientId: '', coiffeuseId: '',),
      debugShowCheckedModeBanner: false,

      // // Définir les routes nommées
      // initialRoute: '/',
      // routes: {
      //   //'/': (context) => const SplashScreen(),
      //   '/home': (context) => const HomePage(),
      //   '/login': (context) => const LoginPage(),
      //   '/paiement-success': (context) => const PaiementSuccessPage(),
      //   '/paiement-error': (context) => const PaiementErrorPage(),
      // },

      // Ne définissez pas initialRoute ni routes
      onGenerateRoute: (settings) {
        // Si c'est la route d'accueil
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(
            builder: (context) => const HomePage(),
          );
        }

        // Sinon, utilisez le RouteService pour les autres routes
        return RouteService().generateRoute(settings);
      },
    );
  }

}







// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/pages/payment/paiement_sucess_page.dart';
// import 'firebase_options.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
// import 'package:provider/provider.dart';
// import 'package:hairbnb/pages/splash_screen.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/services/providers/disponibilites_provider.dart';
// import 'package:hairbnb/services/routes_services/route_service.dart';
//
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//   }
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // 🔍 Lire l'URL actuelle dans le navigateur
//   final uri = Uri.base;
//   final path = uri.path;
//   final sessionId = uri.queryParameters['session_id'];
//
//   // 📍 Définir la route initiale
//   String initialRoute = '/';
//   Object? initialArguments;
//
//   if (kIsWeb && path == '/success' && sessionId != null) {
//     initialRoute = '/paiement-success';
//     initialArguments = {'sessionId': sessionId};
//   }
//
//   // ⚙️ Initialisation Firebase
//   if (kIsWeb) {
//     setUrlStrategy(PathUrlStrategy());
//     print('✅ Configuration Web effectuée');
//     await Firebase.initializeApp(
//       options: FirebaseOptions(
//           apiKey: "AIzaSyBwQnw-rxiMy88yqf-rWUxIuWLTSfiTkEc",
//           authDomain: "hairbnb-7eeb9.firebaseapp.com",
//           databaseURL: "https://hairbnb-7eeb9-default-rtdb.europe-west1.firebasedatabase.app",
//           projectId: "hairbnb-7eeb9",
//           storageBucket: "hairbnb-7eeb9.appspot.com",
//           messagingSenderId: "523426514457",
//           appId: "1:523426514457:web:c12474ba6a3bed7ef08c88",
//           measurementId: "G-E9GTDH2YCN"
//       ),
//     );
//   } else {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//   }
//
//   HttpOverrides.global = MyHttpOverrides();
//
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => CurrentUserProvider()),
//         ChangeNotifierProvider(create: (_) => CartProvider()),
//         ChangeNotifierProvider(create: (_) => DisponibilitesProvider()),
//       ],
//       child: MyApp(
//         initialRoute: initialRoute,
//         initialArguments: initialArguments,
//       ),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   final String initialRoute;
//   final Object? initialArguments;
//
//   const MyApp({super.key, required this.initialRoute, this.initialArguments});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hairbnb app',
//       theme: ThemeData(primarySwatch: Colors.deepPurple),
//       debugShowCheckedModeBanner: false,
//       initialRoute: initialRoute,
//       onGenerateRoute: (settings) {
//         final args = settings.arguments ?? initialArguments;
//
//         if (settings.name == '/' || settings.name == null) {
//           return MaterialPageRoute(builder: (_) => const SplashScreen());
//         }
//
//         if (settings.name == '/paiement-success') {
//           return MaterialPageRoute(
//             //builder: (_) =>
//             builder: (context) => const HomePage(),
//                 // PaiementSuccessScreen(sessionId: (args as Map)['sessionId']),
//           );
//         }
//
//         return RouteService().generateRoute(settings);
//       },
//     );
//   }
// }
//
//





// import 'dart:io';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:hairbnb/pages/home_page.dart';
// import 'package:hairbnb/services/providers/cart_provider.dart';
// import 'package:hairbnb/services/providers/disponibilites_provider.dart';
// import 'package:hairbnb/services/routes_services/route_service.dart';
// import 'firebase_options.dart';
// import 'package:hairbnb/pages/splash_screen.dart';
// import 'package:provider/provider.dart';
// import 'services/providers/current_user_provider.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
//
//
//
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//   }
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//
//   // if (kIsWeb) {
//   //   // Configurer l'URL strategy pour le web uniquement
//   //   WebUrlService().configureWebUrlStrategy();
//   // }
//
//
//  //  if (!kIsWeb) {
//  //    // 🔐 Initialisation Stripe
//  //    Stripe.publishableKey =
//  //    "pk_test_51QxTcwPLEsfXjeyfbxYM0qSVUfouAqtUGbVOTXmf3fr3y6tBtX5aylUzP3xLPniIXWu7hmuBGdvIWJ6fueZZe70d00dn2sPdfv";
//  //    Stripe.merchantIdentifier = 'hairbnb_merchant';
//  //    Stripe.urlScheme = 'hairbnb';
//  //
//  //  await Stripe.instance.applySettings();
//  // }
//
//   if (kIsWeb) {
//     setUrlStrategy(PathUrlStrategy());
//     print('✅ Configuration Web effectuée');
//     await Firebase.initializeApp(
//       options: FirebaseOptions(
//         apiKey: "AIzaSyBwQnw-rxiMy88yqf-rWUxIuWLTSfiTkEc",
//         authDomain: "hairbnb-7eeb9.firebaseapp.com",
//         databaseURL: "https://hairbnb-7eeb9-default-rtdb.europe-west1.firebasedatabase.app",
//         projectId: "hairbnb-7eeb9",
//         storageBucket: "hairbnb-7eeb9.firebasestorage.app",
//         messagingSenderId: "523426514457",
//         appId: "1:523426514457:web:c12474ba6a3bed7ef08c88",
//         measurementId: "G-E9GTDH2YCN"
//       ),
//     );
//   } else {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );}
//
//   HttpOverrides.global = MyHttpOverrides();
//
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => CurrentUserProvider()), // 🔥 Initialisation de `UserProvider
//         ChangeNotifierProvider(create: (context) => CartProvider()),//
//         ChangeNotifierProvider(create: (_) => DisponibilitesProvider()), // ✅ ici// `
//       ],
//       //child: const AppRoot(),
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hairbnb app',
//       theme: ThemeData(primarySwatch: Colors.deepPurple),
//       //home:  const LoginPage(),
//       home: const SplashScreen(), // Utilisation de SplashScreen
//       //home: const CreateServicesPage(),
//       //home: const CreateSalonPage(userUuid: 'xxx',),
//       //home: const ChatsScreen(),
//       //home: const ProfileCreationPage(),
//       //home : const OSMTestPage(),
//       //home:const ServicesListPage(coiffeuseId: 'coiffeuseId',),
//       //home: SearchCoiffeusePage(),
//       //home: ChatPage(clientId: '', coiffeuseId: '',),
//       debugShowCheckedModeBanner: false,
//
//       // // Définir les routes nommées
//       // initialRoute: '/',
//       // routes: {
//       //   //'/': (context) => const SplashScreen(),
//       //   '/home': (context) => const HomePage(),
//       //   '/login': (context) => const LoginPage(),
//       //   '/paiement-success': (context) => const PaiementSuccessPage(),
//       //   '/paiement-error': (context) => const PaiementErrorPage(),
//       // },
//
//       // Ne définissez pas initialRoute ni routes
//       onGenerateRoute: (settings) {
//         // Si c'est la route d'accueil
//         if (settings.name == '/' || settings.name == null) {
//           return MaterialPageRoute(
//             builder: (context) => const HomePage(),
//           );
//         }
//
//         // Sinon, utilisez le RouteService pour les autres routes
//         return RouteService().generateRoute(settings);
//       },
//     );
//   }
//
// }
//
