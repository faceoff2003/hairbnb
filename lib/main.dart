import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hairbnb/pages/ai_chat/providers/ai_chat_provider.dart';
import 'package:hairbnb/pages/ai_chat/services/ai_chat_service.dart';
import 'package:hairbnb/pages/ai_chat/services/coiffeuse_ai_chat_service.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/services/notifications_services/notification_service.dart';
import 'package:hairbnb/services/providers/cart_provider.dart';
import 'package:hairbnb/services/providers/coiffeuse_ai_chat_provider.dart';
import 'package:hairbnb/services/providers/disponibilites_provider.dart';
import 'package:hairbnb/services/providers/revenus_provider.dart';
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


  if (kIsWeb) {
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
  );

  // Initialiser les notifications
  //await NotificationService.initialize();

  // ✅ DÉMARRER les notifications en arrière-plan (non-bloquant)
  NotificationService.initialize().catchError((e) {
    print("⚠️ Erreur notifications (non-bloquant): $e");
  });

  if (kDebugMode) {
    print("✅ Application initialisée avec succès");
  }
  }

  // Initialiser le service de notifications
  // await NotificationService.initialize();

  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        // Seulement CurrentUserProvider au démarrage
        ChangeNotifierProvider(create: (_) => CurrentUserProvider()),

        // ✅ LAZY : Chargement à la demande
        ChangeNotifierProvider(create: (_) => CartProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DisponibilitesProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => RevenusProvider(), lazy: true),

        // ✅ TRÈS LAZY : AI Providers seulement quand on va sur la page AI
        ChangeNotifierProvider(
          create: (context) => AIChatProvider(AIChatService(
            baseUrl: 'https://www.hairbnb.site/api',
            token: '',
          )),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (context) => CoiffeuseAIChatProvider(
            CoiffeuseAIChatService(
              baseUrl: 'https://www.hairbnb.site/api',
              token: '',
            ),
          ),
          lazy: true,
        ),
      ],
      child: const MyApp(),
    ),
    // MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => CurrentUserProvider()),
    //     ChangeNotifierProvider(create: (context) => CartProvider()),//
    //     ChangeNotifierProvider(create: (_) => DisponibilitesProvider()),
    //     ChangeNotifierProvider(create: (context) => AIChatProvider(AIChatService(
    //           baseUrl: 'https://www.hairbnb.site/api',
    //           token: '',
    //         ),
    //       ),
    //     ),
    //     ChangeNotifierProvider(create: (context) => CoiffeuseAIChatProvider(
    //       CoiffeuseAIChatService(
    //         baseUrl: 'https://www.hairbnb.site/api',
    //         token: '',
    //       ),
    //     ),
    //     ),
    //   ],
    //   //child: const AppRoot(),
    //   child: const MyApp(),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 🆕 NavigatorKey global pour les notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // 🆕 Configurer le NavigatorKey pour les notifications
    NotificationService.setNavigatorKey(navigatorKey);

    return MaterialApp(
      title: 'Hairbnb app',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const SplashScreen(),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

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
