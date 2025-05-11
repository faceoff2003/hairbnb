// // Créez un nouveau fichier app_scaffold.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:hairbnb/services/providers/current_user_provider.dart';
// import 'package:hairbnb/widgets/custom_app_bar.dart';
// import 'package:hairbnb/services/my_drawer_service/my_drawer.dart';
//
// class AppScaffold extends StatelessWidget {
//   final Widget body;
//   final Widget? bottomNavigationBar;
//   final bool? resizeToAvoidBottomInset;
//
//   const AppScaffold({
//     Key? key,
//     required this.body,
//     this.bottomNavigationBar,
//     this.resizeToAvoidBottomInset,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUserProvider = Provider.of<CurrentUserProvider>(context);
//     final currentUser = currentUserProvider.currentUser;
//
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       drawer: currentUser != null ? MyDrawer(currentUser: currentUser) : null,
//       body: body,
//       bottomNavigationBar: bottomNavigationBar,
//       resizeToAvoidBottomInset: resizeToAvoidBottomInset,
//     );
//   }
// }





// // Créez un fichier app_scaffold.dart
// import 'package:flutter/material.dart';
// import 'package:hairbnb/models/current_user.dart';
// import 'package:hairbnb/widgets/custom_app_bar.dart';
// import 'package:hairbnb/widgets/bottom_nav_bar.dart';
//
// import 'my_drawer.dart';
//
// class AppScaffold extends StatelessWidget {
//   final CurrentUser currentUser;
//   final Widget body;
//   final int currentNavIndex;
//   final Function(int)? onNavTap;
//
//   const AppScaffold({
//     Key? key,
//     required this.currentUser,
//     required this.body,
//     this.currentNavIndex = 0,
//     this.onNavTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(),
//       drawer: MyDrawer(currentUser: currentUser),
//       body: body,
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: currentNavIndex,
//         onTap: onNavTap ?? (index) {},
//       ),
//     );
//   }
// }