import 'package:flutter/material.dart';
import 'package:hairbnb/widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Définir les widgets pour chaque page
  final List<Widget> _pages = [
    Center(child: Text('Page Accueil')),
    Center(child: Text('Page Rechercher')),
    Center(child: Text('Page Réservations')),
    Center(child: Text('Page Messages')),
    Center(child: Text('Page Profil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hairbnb'),
        backgroundColor: Colors.purple,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
