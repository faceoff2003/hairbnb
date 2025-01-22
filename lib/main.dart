import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/chat/chat_page.dart';
import 'package:hairbnb/pages/chat/messages_page.dart';
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
  );}


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
    );
  }
}
