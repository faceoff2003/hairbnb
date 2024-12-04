import 'package:flutter/material.dart';
import 'package:hairbnb/pages/chat/chats_screens.dart';
import 'package:hairbnb/pages/coiffeuses/search_coiffeuse_page.dart';
import 'package:hairbnb/pages/home_page.dart';
import 'package:hairbnb/pages/login_page.dart';
import 'package:hairbnb/pages/profil/profil_creation_page.dart';
import 'package:hairbnb/pages/salon/create_salon_page.dart';
import 'package:hairbnb/pages/salon/salon_services_list/create_services_page.dart';
import 'package:hairbnb/pages/salon/salon_services_list/show_services_list_page.dart';
import 'package:hairbnb/pages/signin_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hairbnb/pages/test_api.dart';
import 'firebase_options.dart';
import 'package:hairbnb/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
      //home: const SplashScreen(), // Utilisation de SplashScreen
      //home: const CreateServicesPage(),
      //home: const CreateSalonPage(userUuid: 'xxx',),
      //home: const ChatsScreen(),
      //home: const ProfileCreationPage(),
      //home : const OSMTestPage(),
      home:const ServicesListPage(coiffeuseId: 'coiffeuseId',),
      //home: SearchCoiffeusePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
