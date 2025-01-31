import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
