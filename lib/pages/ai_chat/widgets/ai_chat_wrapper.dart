// lib/pages/ai_chat/ai_chat_wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';

import '../conversations_list_page.dart';
import '../providers/ai_chat_provider.dart';
import '../services/ai_chat_service.dart';

class AIChatWrapper extends StatelessWidget {
  final CurrentUser currentUser;

  const AIChatWrapper({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: FirebaseAuth.instance.currentUser?.getIdToken(true).then((token) => token ?? '')
          ?? Future.value(''),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final firebaseToken = snapshot.data!;

        // Utiliser ChangeNotifierProvider.value pour s'assurer que le provider est accessible
        return ChangeNotifierProvider(
          create: (context) => AIChatProvider(
            AIChatService(
              baseUrl: 'https://www.hairbnb.site/api',
              token: firebaseToken,
            ),
          ),
          // Assurer que le contexte est correctement transmis
          child: Consumer<AIChatProvider>(
            builder: (context, provider, _) {
              return MaterialApp(
                home: ConversationsListPage(currentUser: currentUser),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }
}