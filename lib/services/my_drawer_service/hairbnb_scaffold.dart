import 'package:flutter/material.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/widgets/custom_app_bar.dart';
import 'package:hairbnb/services/my_drawer_service/my_drawer.dart';
import 'package:provider/provider.dart';

class HairbnbScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const HairbnbScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentUserProvider>(
        builder: (context, userProvider, _) {
      final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: MyDrawer(currentUser: currentUser),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
    );
  }
}