// screens/debug_avis_screen.dart

import 'package:flutter/material.dart';

import 'debug_avis_service.dart';

class DebugAvisScreen extends StatefulWidget {
  const DebugAvisScreen({Key? key}) : super(key: key);

  @override
  _DebugAvisScreenState createState() => _DebugAvisScreenState();
}

class _DebugAvisScreenState extends State<DebugAvisScreen> {
  String _debugOutput = "Appuyez sur un bouton pour commencer le debug...";
  bool _isLoading = false;

  void _runDebugTest(String testName, Future<void> Function() test) async {
    setState(() {
      _isLoading = true;
      _debugOutput = "🔄 Exécution du test: $testName...\n";
    });

    try {
      await test();
      setState(() {
        _debugOutput += "\n✅ Test terminé avec succès !";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugOutput += "\n❌ Erreur pendant le test: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Debug Avis'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Boutons de test
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '🚨 Debug du problème "No TblClient matches"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                // Bouton debug complet
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      _runDebugTest(
                        "Debug Complet",
                            () => DebugAvisService.debugComplet(context),
                      );
                    },
                    icon: Icon(Icons.bug_report),
                    label: Text('🚨 DEBUG COMPLET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Tests individuels
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          _runDebugTest(
                            "Utilisateur",
                                () => DebugAvisService.debugCurrentUser(context),
                          );
                        },
                        child: Text('👤 User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          _runDebugTest(
                            "Token",
                                () => DebugAvisService.debugFirebaseToken(),
                          );
                        },
                        child: Text('🔑 Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          _runDebugTest(
                            "API Publique",
                                () => DebugAvisService.debugApiPublic(),
                          );
                        },
                        child: Text('🌐 API'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          _runDebugTest(
                            "Mes RDV",
                                () => DebugAvisService.debugApiMesRdv(),
                          );
                        },
                        child: Text('📅 RDV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Zone d'affichage des résultats
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Console Debug',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Text(
                      _debugOutput,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Text(
              '💡 Instructions:\n'
                  '1. Cliquez sur "DEBUG COMPLET" pour analyser le problème\n'
                  '2. Regardez la console Flutter pour les détails\n'
                  '3. Partagez les résultats pour qu\'on puisse corriger',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}