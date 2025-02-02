import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profil/profil_creation_page.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  late Color myColor;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Ajout de la clé pour la validation
  bool isPasswordVisible = false;
  bool isLoading = false; // Pour l'indicateur de chargement

  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: myColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: _buildTop(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottom(),
            ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_sharp,
          size: 100,
          color: Colors.white,
        ),
        const Text(
          "Hairbnb",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 40,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildBottom() {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bienvenue",
          style: TextStyle(
            color: myColor,
            fontSize: 32,
            fontWeight: FontWeight.w500,
          ),
        ),
        _buildGreyText("Veuillez vous inscrire avec vos informations"),
        const SizedBox(height: 30),
        _buildGreyText("Adresse e-mail"),
        _buildInputField(
          controller: emailController,
          hintText: "Entrez votre email",
          validator: validateEmail,
        ),
        const SizedBox(height: 20),
        _buildGreyText("Mot de passe"),
        _buildInputField(
          controller: passwordController,
          hintText: "Entrez votre mot de passe",
          isPassword: true,
          validator: validatePassword,
        ),
        const SizedBox(height: 20),
        _buildGreyText("Confirmez le mot de passe"),
        _buildInputField(
          controller: confirmPasswordController,
          hintText: "Confirmez votre mot de passe",
          isPassword: true,
          validator: validatePasswords,
        ),
        const SizedBox(height: 30),
        _buildSigninButton(),
      ],
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        )
            : null,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
    );
  }

  Widget _buildSigninButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          setState(() => isLoading = true);
          await _signupUser(emailController.text, passwordController.text);
          setState(() => isLoading = false);
        }
      },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 0,
        backgroundColor: myColor,
        foregroundColor: Colors.white,
        side: BorderSide(color: myColor, width: 2),
        minimumSize: const Size.fromHeight(60),
      ),
      child: const Text("Inscription"),
    );
  }

  Future<void> _signupUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Récupérer l'UID et l'email
      String userEmail = userCredential.user?.email ?? "";
      String userUID = userCredential.user?.uid ?? "";

      debugPrint("Utilisateur inscrit : Email = $userEmail, UID = $userUID");

      // Redirection vers la page de création de profil avec les données de l'utilisateur
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCreationPage(
            email: userEmail,
            userUuid: userUID,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Une erreur s'est produite";
      debugPrint(message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint("Erreur inconnue : $e");
    }
  }

  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Format d\'email invalide.';
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Veuillez entrer un mot de passe.';
    if (password.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères.';
    return null;
  }

  String? validatePasswords(String? confirmPassword) {
    if (confirmPassword != passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }
}











// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hairbnb/pages/authentification/authentification_services/login_with_google.dart';
// import '../../services/auth_services/auth_service.dart';
// import '../profil/profil_creation_page.dart';
// import 'authentification_services/sign_up_with_facebook.dart';
//
//
// class SigninPage extends StatefulWidget {
//
//   const SigninPage({super.key});
//
//   @override
//   State<SigninPage> createState() => _SigninPageState();
// }
//
// class _SigninPageState extends State<SigninPage> {
//   late Color myColor;
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();
//   bool isPasswordVisible = false;
//   bool isLoading = false; // Pour afficher un indicateur de chargement
//
//
//   @override
//   Widget build(BuildContext context) {
//     myColor = Theme.of(context).primaryColor;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: myColor,
//         image: DecorationImage(
//           image: const AssetImage("assets/img/bg.png"),
//           fit: BoxFit.cover,
//           colorFilter: ColorFilter.mode(
//             //myColor.withOpacity(0.2),
//             myColor.withAlpha((0.2 * 255).toInt()),
//             BlendMode.dstATop,
//           ),
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return Stack(
//                 children: [
//                   Positioned(
//                     top: 80,
//                     child: _buildTop(constraints),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     child: _buildBottom(constraints),
//                   ),
//                   if (isLoading) // Affiche un indicateur de chargement si nécessaire
//                     const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildTop(BoxConstraints constraints) {
//     return SizedBox(
//       width: constraints.maxWidth,
//       child: const Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.location_on_sharp,
//             size: 100,
//             color: Colors.white,
//           ),
//           Text(
//             "Hairbnb",
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 40,
//               letterSpacing: 2,
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildBottom(BoxConstraints constraints) {
//     return SizedBox(
//       width: constraints.maxWidth,
//       height: constraints.maxHeight * 0.7,
//       child: Card(
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(30),
//             topRight: Radius.circular(30),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: SingleChildScrollView(
//             child: _buildForm(),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Bienvenue",
//           style: TextStyle(
//             color: myColor,
//             fontSize: 32,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         _buildGreyText("Veuillez vous inscrire avec vos informations"),
//         const SizedBox(height: 40),
//         _buildGreyText("Adresse e-mail"),
//         _buildInputField(
//           emailController,
//           hintText: "Entrez votre email",
//           validator: validateEmail,
//         ),
//         const SizedBox(height: 30),
//         _buildGreyText("Mot de passe"),
//         _buildInputField(
//           passwordController,
//           hintText: "Entrez votre mot de passe",
//           isPassword: true,
//           validator: validatePassword,
//         ),
//         const SizedBox(height: 30),
//         _buildGreyText("Confirmez le mot de passe"),
//         _buildInputField(
//           confirmPasswordController,
//           hintText: "Confirmez votre mot de passe",
//           isPassword: true,
//           validator: (_) => validatePasswords(),
//         ),
//         const SizedBox(height: 20),
//         _buildSigninButton(),
//         const SizedBox(height: 20),
//         _buildOtherSignin(),
//       ],
//     );
//   }
//
//   Widget _buildGreyText(String text) {
//     return Text(
//       text,
//       style: const TextStyle(color: Colors.grey),
//     );
//   }
//
//
//   Widget _buildInputField(
//       TextEditingController controller, {
//         required String hintText,
//         required String? Function(String?) validator,
//         bool isPassword = false,
//       }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword && !isPasswordVisible,
//       keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
//       textInputAction: TextInputAction.next,
//       decoration: InputDecoration(
//         hintText: hintText,
//         suffixIcon: isPassword
//             ? IconButton(
//           icon: Icon(
//             isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//           ),
//           onPressed: () {
//             setState(() {
//               isPasswordVisible = !isPasswordVisible;
//             });
//           },
//         )
//             : null,
//       ),
//       autovalidateMode: AutovalidateMode.onUserInteraction,
//       validator: validator,
//     );
//   }
//
//
//   String? validateEmail(String? email) {
//     if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
//     final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
//     if (!emailRegex.hasMatch(email)) return 'Format d\'email invalide.';
//     return null;
//   }
//
//
//   String? validatePassword(String? password) {
//     if (password == null || password.isEmpty) {
//       return 'Veuillez entrer un mot de passe.';
//     }
//     if (password.length < 12) {
//       return 'Le mot de passe doit contenir au moins 12 caractères.';
//     }
//     final upperCaseRegex = RegExp(r'[A-Z]');
//     if (!upperCaseRegex.hasMatch(password)) {
//       return 'Le mot de passe doit contenir au moins une majuscule.';
//     }
//     final numberRegex = RegExp(r'[0-9]');
//     if (!numberRegex.hasMatch(password)) {
//       return 'Le mot de passe doit contenir au moins un chiffre.';
//     }
//     final specialCharRegex = RegExp(r'[!@#\$%\^&\*]');
//     if (!specialCharRegex.hasMatch(password)) {
//       return 'Le mot de passe doit contenir au moins un caractère spécial (!, @, #, \$, %, ^).';
//     }
//     return null;
//   }
//
//   String? validatePasswords() {
//     if (passwordController.text != confirmPasswordController.text) {
//       return 'Les mots de passe ne correspondent pas.';
//     }
//     return null;
//   }
//
//
//   Widget _buildSigninButton() {
//     return ElevatedButton(
//       onPressed: () async {
//         if (_formIsValid()) {
//           setState(() => isLoading = true);
//           await _signupUser(emailController.text as BuildContext, passwordController.text);
//           setState(() => isLoading = false);
//         } else {
//           debugPrint("Formulaire invalide.");
//         }
//       },
//       style: ElevatedButton.styleFrom(
//         shape: const StadiumBorder(),
//         elevation: 0,
//         backgroundColor: myColor,
//         foregroundColor: Colors.white,
//         side: BorderSide(color: myColor, width: 2),
//         minimumSize: const Size.fromHeight(60),
//       ),
//       child: const Text("Inscription"),
//     );
//   }
//
//   Future<void> _signupUser(BuildContext context, String email, String password) async {
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Récupérer l'UID et l'email
//       String? userEmail = userCredential.user?.email;
//       String? userUID = userCredential.user?.uid;
//
//       debugPrint("Utilisateur inscrit : Email = $userEmail, UID = $userUID");
//
//       // Redirection vers la page de création de profil avec les données de l'utilisateur
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProfileCreationPage(
//             email: userEmail ?? "",
//             userUuid: '',
//           ),
//         ),
//       );
//
//     } on FirebaseAuthException catch (e) {
//       String message;
//       if (e.code == 'weak-password') {
//         message = "Le mot de passe est trop faible.";
//       } else if (e.code == 'email-already-in-use') {
//         message = "Cet email est déjà utilisé.";
//       } else if (e.code == 'invalid-email') {
//         message = "Email invalide.";
//       } else {
//         message = "Erreur : ${e.message}";
//       }
//
//       debugPrint(message);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     } catch (e) {
//       debugPrint("Erreur inconnue : $e");
//     }
//   }

  // Future<void> _signupUser(String email, String password) async {
  //   try {
  //     UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     debugPrint("Utilisateur inscrit : ${userCredential.user?.email}");
  //     // Redirection ou autre logique après succès
  //   } on FirebaseAuthException catch (e) {
  //     String message;
  //     if (e.code == 'weak-password') {
  //       message = "Le mot de passe est trop faible.";
  //     } else if (e.code == 'email-already-in-use') {
  //       message = "Cet email est déjà utilisé.";
  //     } else if (e.code == 'invalid-email') {
  //       message = "Email invalide.";
  //     } else {
  //       message = "Erreur : ${e.message}";
  //     }
  //     debugPrint(message);
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   //   } catch (e) {
//   //     debugPrint("Erreur inconnue : $e");
//   //   }
//   // }
//
//   bool _formIsValid() {
//     return validateEmail(emailController.text) == null &&
//         validatePassword(passwordController.text) == null &&
//         validatePasswords() == null;
//   }
//
//
//   Widget _buildOtherSignin() {
//     final authService = AuthService();
//     return Center(
//       child: Column(
//         children: [
//           _buildGreyText("Ou se connecter avec"),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildSocialIcon('assets/logo_login/google.png', () async {
//                 setState(() => isLoading = true);
//                 try {
//                   final user = await loginWithGoogle(context);
//                   if (user != null) {
//                     debugPrint("Utilisateur connecté via Google: ${user.email}");
//                   }
//                 } catch (e) {
//                   debugPrint("Erreur Google Sign-In: $e");
//                 } finally {
//                   setState(() => isLoading = false);
//                 }
//               }),
//               _buildSocialIcon('assets/logo_login/facebook.png', () async {
//                 setState(() => isLoading = true);
//                 try {
//                   final user = await signUpWithFacebook(authService as BuildContext);
//                   if (user != null) {
//                     debugPrint("Utilisateur connecté via Facebook: ${user.email}");
//                   }
//                 } catch (e) {
//                   debugPrint("Erreur Facebook Sign-In: $e");
//                 } finally {
//                   setState(() => isLoading = false);
//                 }
//               }),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSocialIcon(String assetPath, VoidCallback onPressed) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Image.asset(
//         assetPath,
//         width: 40,
//         height: 40,
//         errorBuilder: (context, error, stackTrace) {
//           return const Icon(Icons.error, color: Colors.red);
//         },
//       ),
//     );
//   }
//
// }


// /// Imports necessaires pour la page de connexion.
// ///
// /// * [Material.dart] : classe [MaterialApp] pour afficher la page de connexion.
// /// * [FirebaseAuth] : classe [FirebaseAuth] pour gerer les utilisateurs et leur
// ///   connexion.
// /// * [GoogleSignIn] : classe [GoogleSignIn] pour gerer la connexion avec un compte
// ///   Google.
// /// * [AuthService] : classe [AuthService] pour gerer les differentes methodes de
// ///   connexion (connexion avec email et mot de passe, connexion avec Google, etc).
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../services/auth_services/SignIn_service.dart';
//
//
// /// La page de connexion.
// ///
// /// Cette page permet a l'utilisateur de se connecter en utilisant son adresse
// /// e-mail et son mot de passe, ou en utilisant son compte Google.
// ///
// class SigninPage extends StatefulWidget {
//
//   /// Constructeur de la page de connexion.
//   ///
//   /// Ce constructeur prend un parametre [key] qui est un identifiant unique pour
//   /// l'element de l'arbre d'elements de l'application.
//   ///
//   const SigninPage({super.key});
//
//   @override
//   State<SigninPage> createState() => _SigninPageState();
// }
// //======================================================================================
// /// Bloc de code qui definit la page de connexion.
// ///
// /// Ce bloc de code definit la classe [SigninPage] qui est la page de connexion
// /// de l'application. Cette page permet a l'utilisateur de se connecter en
// /// utilisant son adresse e-mail et son mot de passe, ou en utilisant son compte
// /// Google.
// class _SigninPageState extends State<SigninPage> {
//   late Color myColor;
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController = TextEditingController();
//   bool isPasswordVisible = false;
//   bool isLoading = false; // Pour afficher un indicateur de chargement
//
//
//
//   /// Construit la page de connexion.
//   ///
//   /// Cette methode est appelee par Flutter pour construire la page de connexion.
//   /// Elle utilise le contexte de l'application pour recuperer la couleur primaire
//   /// definie dans le theme, puis utilise cette couleur pour afficher un fond
//   /// avec une image de fond.
//   ///
//   /// La page est ensuite decoupee en deux parties : la partie haute, qui contient
//   /// le logo de l'application, et la partie basse, qui contient le formulaire de
//   /// connexion.
//   ///
//   /// Si l'indicateur de chargement [isLoading] est a [true], un indicateur de
//   /// chargement est affiche.
//   ///
//   @override
//   Widget build(BuildContext context) {
//     myColor = Theme.of(context).primaryColor;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: myColor,
//         image: DecorationImage(
//           image: const AssetImage("assets/logo_login/bg.png"),
//           fit: BoxFit.cover,
//           colorFilter: ColorFilter.mode(
//             myColor.withOpacity(0.2),
//             BlendMode.dstATop,
//           ),
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return Stack(
//                 children: [
//                   Positioned(
//                     top: 80,
//                     child: _buildTop(constraints),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     child: _buildBottom(constraints),
//                   ),
//                   if (isLoading) // Affiche un indicateur de chargement si nécessaire
//                     const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Construit la partie haute de la page de connexion.
//   ///
//   /// Cette methode prend en parametre un objet [BoxConstraints] qui represente
//   /// les contraintes de taille de l'ecran, et utilise ces contraintes pour
//   /// afficher le logo de l'application et le texte "Hairbnb".
//   ///
//   /// La partie haute est affichee en haut de l'ecran, et occupe toute la largeur
//   /// de l'ecran.
//   ///
//
//   Widget _buildTop(BoxConstraints constraints) {
//     return SizedBox(
//       width: constraints.maxWidth,
//       child: const Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.location_on_sharp,
//             size: 100,
//             color: Colors.white,
//           ),
//           Text(
//             "Hairbnb",
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 40,
//               letterSpacing: 2,
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   /// Construit la partie basse de la page de connexion.
//   ///
//   /// Cette methode prend en parametre un objet [BoxConstraints] qui represente
//   /// les contraintes de taille de l'ecran, et utilise ces contraintes pour
//   /// afficher le formulaire de connexion.
//   ///
//   /// La partie basse est affichee en bas de l'ecran, et occupe la totalite de
//   /// la largeur de l'ecran. La hauteur est de 70% de la hauteur de l'ecran.
//   ///
//
//   Widget _buildBottom(BoxConstraints constraints) {
//     return SizedBox(
//       width: constraints.maxWidth,
//       height: constraints.maxHeight * 0.7,
//       child: Card(
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(30),
//             topRight: Radius.circular(30),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: SingleChildScrollView(
//             child: _buildForm(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Construit le formulaire de connexion.
//   ///
//   /// Ce formulaire contient un champ de saisie pour l'adresse e-mail,
//   /// un champ de saisie pour le mot de passe, et un bouton pour se connecter.
//   ///
//   /// Si le formulaire est valide, le bouton est actif et permet de se connecter.
//   /// Sinon, le bouton est inactif.
//   ///
//
//   Widget _buildForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Bienvenue",
//           style: TextStyle(
//             color: myColor,
//             fontSize: 32,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         _buildGreyText("Veuillez vous inscrire avec vos informations"),
//         const SizedBox(height: 40),
//         _buildGreyText("Adresse e-mail"),
//         _buildInputField(
//           emailController,
//           hintText: "Entrez votre email",
//           validator: validateEmail,
//         ),
//         const SizedBox(height: 30),
//         _buildGreyText("Mot de passe"),
//         _buildInputField(
//           passwordController,
//           hintText: "Entrez votre mot de passe",
//           isPassword: true,
//           validator: validatePassword,
//         ),
//         const SizedBox(height: 30),
//         _buildGreyText("Confirmez le mot de passe"),
//         _buildInputField(
//           confirmPasswordController,
//           hintText: "Confirmez votre mot de passe",
//           isPassword: true,
//           validator: (_) => validatePasswords(),
//         ),
//         const SizedBox(height: 20),
//         _buildSigninButton(),
//         const SizedBox(height: 20),
//         _buildOtherSignin(),
//       ],
//     );
//   }
//
//   /// Retourne un [Text] avec le texte [text] affiche en gris.
//   ///
//   /// Cette methode est utilisee pour afficher des textes de couleur grise
//   /// sur la page de connexion.
//
//   Widget _buildGreyText(String text) {
//     return Text(
//       text,
//       style: const TextStyle(color: Colors.grey),
//     );
//   }
//
//   /// Construit un champ de saisie pour le formulaire de connexion.
//   ///
//   /// Ce champ de saisie prend en parametre un [TextEditingController] qui
//   /// represente le champ de saisie, un texte [hintText] affiche comme indice
//   /// pour le champ de saisie, une fonction [validator] qui valide le champ de
//   /// saisie, et un boolean [isPassword] qui indique si le champ de saisie doit
//   /// etre un champ de saisie de mot de passe.
//   ///
//   /// Si [isPassword] est a [true], le champ de saisie est un champ de saisie de
//   /// mot de passe, et il est possible de voir le mot de passe en cliquant sur
//   /// l'icone de visibilite.
//   ///
//
//   Widget _buildInputField(
//       TextEditingController controller, {
//         required String hintText,
//         required String? Function(String?) validator,
//         bool isPassword = false,
//       }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword && !isPasswordVisible,
//       keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
//       textInputAction: TextInputAction.next,
//       decoration: InputDecoration(
//         hintText: hintText,
//         suffixIcon: isPassword
//             ? IconButton(
//           icon: Icon(
//             isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//           ),
//           onPressed: () {
//             setState(() {
//               isPasswordVisible = !isPasswordVisible;
//             });
//           },
//         )
//             : null,
//       ),
//       autovalidateMode: AutovalidateMode.onUserInteraction,
//       validator: validator,
//     );
//   }
//
//   /// Valide un email.
//   ///
//   /// Si l'email est vide ou n'a pas le bon format, une erreur est renvoyee.
//   /// Sinon, [null] est renvoye.
//   ///
//
//   String? validateEmail(String? email) {
//     if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
//     final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
//     if (!emailRegex.hasMatch(email)) return 'Format d\'email invalide.';
//     return null;
//   }
//
//
//   /// Valide un mot de passe.
//   ///
//   /// Si le mot de passe est vide, n'a pas le bon format, n'a pas de majuscule,
//   /// n'a pas de chiffre, ou n'a pas de caractere special, une erreur est renvoyee.
//   /// Sinon, [null] est renvoye.
//   ///
//
//   // Méthode pour valider le mot de passe
//   String? validatePassword(String? password) {
//     if (password == null || password.isEmpty) return 'Veuillez entrer un mot de passe.';
//     if (password.length < 12) return 'Le mot de passe doit contenir au moins 12 caractères.';
//     final upperCaseRegex = RegExp(r'[A-Z]');
//     if (!upperCaseRegex.hasMatch(password)) return 'Le mot de passe doit contenir une majuscule.';
//     final numberRegex = RegExp(r'[0-9]');
//     if (!numberRegex.hasMatch(password)) return 'Le mot de passe doit contenir un chiffre.';
//     final specialCharRegex = RegExp(r'[!@#\$%\^&\*]');
//     if (!specialCharRegex.hasMatch(password)) {
//       return 'Le mot de passe doit contenir un caractère spécial (!, @, #, \$, %, ^).';
//     }
//     return null;
//   }
//
//   // Méthode pour vérifier que les mots de passe concordent
//   String? validatePasswords() {
//     if (passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
//       return 'Veuillez remplir les champs de mot de passe.';
//     }
//     if (passwordController.text != confirmPasswordController.text) {
//       return 'Les mots de passe ne correspondent pas.';
//     }
//     return null;
//   }
//
//   /// Bouton de connexion.
//   ///
//   /// Lorsque le bouton est appuye, la methode [_signupUser] est appelee pour
//   /// creer un utilisateur avec l'email et le mot de passe saisis dans les
//   /// champs de formulaire. Si l'inscription se deroule correctement, le bouton
//   /// est desactive pendant l'attente de la reponse du serveur.
//   ///
//
//   Widget _buildSigninButton() {
//     return ElevatedButton(
//       onPressed: () async {
//         // Vérifie que les champs ne sont pas vides et que les mots de passe concordent
//         if (!_formIsValid()) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Veuillez vérifier vos informations et les mots de passe."),
//             ),
//           );
//           return;
//         }
//
//         // Exécute l'inscription
//         final authService = AuthService();
//         await authService.signUpWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//           context: context,
//           emailController: emailController,
//           passwordController: passwordController,
//         );
//
//         debugPrint("Création de compte en cours...");
//       },
//       style: ElevatedButton.styleFrom(
//         shape: const StadiumBorder(),
//         elevation: 0,
//         backgroundColor: myColor,
//         foregroundColor: Colors.white,
//         side: BorderSide(color: myColor, width: 2),
//         minimumSize: const Size.fromHeight(60),
//       ),
//       child: const Text("Inscription"),
//     );
//   }
//
//
//
//   /// Inscription de l'utilisateur avec email et mot de passe.
//   ///
//   /// Tente de créer un nouvel utilisateur avec l'email et le mot de passe
//   /// fournis. Affiche un message de succès ou d'erreur selon le résultat.
//   ///
//   /// [email] L'adresse email de l'utilisateur.
//   /// [password] Le mot de passe de l'utilisateur.
//   ///
//   ///
//
//
//
//
//
//   /// Vérifie si le formulaire d'inscription est valide.
//   ///
//   /// Retourne [true] si le formulaire est valide, [false] sinon.
//   ///
//   /// Un formulaire est valide si :
//   /// - l'email est valide,
//   /// - le mot de passe est valide,
//   /// - les deux mots de passe sont identiques.
//   ///
//   /// Les erreurs sont gérées par les fonctions [validateEmail],
//   /// [validatePassword] et [validatePasswords].
//   ///
//   ///
//   bool _formIsValid() {
//     String? emailError = validateEmail(emailController.text);
//     String? passwordError = validatePassword(passwordController.text);
//     String? confirmPasswordError = validatePasswords();
//
//     // Vérifie si toutes les validations sont OK
//     if (emailError == null &&
//         passwordError == null &&
//         confirmPasswordError == null) {
//       return true;
//     }
//     return false;
//   }
//
//
//   /// Bouton de connexion avec Google et Facebook.
//   ///
//   /// Lorsque l'un des boutons est appuye, la methode [_signInWithGoogle] ou
//   /// [_signInWithFacebook] est appelee pour connecter l'utilisateur avec son compte
//   /// Google ou Facebook. Si la connexion se deroule correctement, le bouton est
//   /// desactive pendant l'attente de la reponse du serveur.
//   ///
//
//   Widget _buildOtherSignin() {
//     final authService = AuthService();
//     return Center(
//       child: Column(
//         children: [
//           _buildGreyText("Ou se connecter avec"),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildSocialIcon('assets/logo_login/google.png', () async {
//                 setState(() => isLoading = true);
//                 try {
//                   final user = await authService.signInWithGoogle(context);
//                   if (user != null) {
//                     debugPrint("Utilisateur connecté via Google: ${user.email}");
//                   }
//                 } catch (e) {
//                   debugPrint("Erreur Google Sign-In: $e");
//                 } finally {
//                   setState(() => isLoading = false);
//                 }
//               }),
//               //              _buildSocialIcon('assets/logo_login/facebook.png', () async {
// //                setState(() => isLoading = true);
// //                try {
// //                  final user = await authService.signInWithFacebook();
// //                  if (user != null) {
// //                    debugPrint("Utilisateur connecté via Facebook: ${user.email}");
// //                  }
// //                } catch (e) {
// //                  debugPrint("Erreur Facebook Sign-In: $e");
// //                } finally {
// //                  setState(() => isLoading = false);
// //                }
// //              }),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Builds a social icon widget.
//   ///
//   /// This widget displays an icon based on the provided asset path. When the
//   /// icon is tapped, the provided callback is executed. If the image fails to
//   /// load, an error icon is displayed instead.
//   ///
//   /// [assetPath] The path to the image asset for the social icon.
//   /// [onPressed] The callback to execute when the icon is tapped.
//   ///
//   ///
//   Widget _buildSocialIcon(String assetPath, VoidCallback onPressed) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Image.asset(
//         assetPath,
//         width: 40,
//         height: 40,
//         errorBuilder: (context, error, stackTrace) {
//           return const Icon(Icons.error, color: Colors.red);
//         },
//       ),
//     );
//   }
//
// }
