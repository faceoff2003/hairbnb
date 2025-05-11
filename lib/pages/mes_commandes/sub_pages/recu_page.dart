import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceiptPage extends StatelessWidget {
  final String receiptUrl;
  const ReceiptPage({super.key, required this.receiptUrl});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(receiptUrl);
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Impossible d\'ouvrir le reçu';
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture de l\'URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lancer automatiquement l'URL lors de l'affichage de cette page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchUrl();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu de paiement'),
        backgroundColor: Colors.purple.shade100,
        // Ajout d'un bouton de retour explicite si nécessaire
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ouverture du reçu dans le navigateur...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Bouton pour ouvrir à nouveau le reçu
            ElevatedButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Ouvrir à nouveau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            // Bouton pour revenir à la page précédente
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}







// // Si vous préférez ne pas utiliser WebView, voici une solution plus simple
// // qui ouvre directement le reçu dans le navigateur externe:
//
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ReceiptPage extends StatelessWidget {
//   final String receiptUrl;
//
//   const ReceiptPage({super.key, required this.receiptUrl});
//
//   Future<void> _launchUrl() async {
//     final Uri url = Uri.parse(receiptUrl);
//     try {
//       if (!await launchUrl(
//         url,
//         mode: LaunchMode.externalApplication,
//       )) {
//         throw 'Impossible d\'ouvrir $url';
//       }
//     } catch (e) {
//       print('Erreur lors de l\'ouverture de l\'URL: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Lancer automatiquement l'URL lors de l'affichage de cette page
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _launchUrl();
//     });
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reçu de paiement'),
//         backgroundColor: Colors.purple.shade100,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.receipt_long,
//               size: 80,
//               color: Colors.purple,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Ouverture du reçu dans le navigateur...',
//               style: TextStyle(fontSize: 18),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               onPressed: _launchUrl,
//               icon: const Icon(Icons.open_in_browser),
//               label: const Text('Ouvrir à nouveau'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'URL: $receiptUrl',
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// // Ajoutez d'abord ces imports au début de votre fichier:
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// // Ensuite, remplacez toute la classe ReceiptPage par celle-ci:
//
// class ReceiptPage extends StatefulWidget {
//   final String receiptUrl;
//
//   const ReceiptPage({super.key, required this.receiptUrl});
//
//   @override
//   State<ReceiptPage> createState() => _ReceiptPageState();
// }
//
// class _ReceiptPageState extends State<ReceiptPage> {
//   late WebViewController controller;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             setState(() {
//               isLoading = true;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               isLoading = false;
//             });
//           },
//           onWebResourceError: (WebResourceError error) {
//             // Gérer les erreurs
//             print('Erreur WebView: ${error.description}');
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.receiptUrl));
//   }
//
//   Future<void> _openInBrowser() async {
//     final Uri url = Uri.parse(widget.receiptUrl);
//     if (!await launchUrl(
//       url,
//       mode: LaunchMode.externalApplication,
//     )) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Impossible d\'ouvrir l\'URL dans le navigateur'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reçu de paiement'),
//         backgroundColor: Colors.purple.shade100,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.open_in_browser),
//             onPressed: _openInBrowser,
//             tooltip: 'Ouvrir dans le navigateur',
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: controller),
//           if (isLoading)
//             const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.purple,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }