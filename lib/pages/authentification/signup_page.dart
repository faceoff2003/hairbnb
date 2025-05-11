import 'package:email_validator/email_validator.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: myColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 80, left: 0, right: 0, child: _buildTop()),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottom()),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.location_on_sharp, size: 100, color: Colors.white),
        Text(
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
        Text("Bienvenue", style: TextStyle(color: myColor, fontSize: 32, fontWeight: FontWeight.w500)),
        _buildGreyText("Veuillez vous inscrire avec vos informations"),
        const SizedBox(height: 30),
        _buildGreyText("Adresse e-mail"),
        _buildInputField(controller: emailController, hintText: "Entrez votre email", validator: validateEmail),
        const SizedBox(height: 20),
        _buildGreyText("Mot de passe"),
        _buildInputField(controller: passwordController, hintText: "Entrez votre mot de passe", isPassword: true, validator: validatePassword),
        const SizedBox(height: 20),
        _buildGreyText("Confirmez le mot de passe"),
        _buildInputField(controller: confirmPasswordController, hintText: "Confirmez votre mot de passe", isPassword: true, validator: validatePasswords),
        const SizedBox(height: 30),
        _buildSigninButton(),
      ],
    );
  }

  Widget _buildGreyText(String text) => Text(text, style: const TextStyle(color: Colors.grey));

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
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
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
          await _signupUser(emailController.text.trim(), passwordController.text);
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

      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📧 Email de vérification envoyé. Veuillez vérifier votre boîte mail."),
          ),
        );

        // 🔒 On ne redirige pas vers la suite tant que l'utilisateur n'a pas confirmé son email
        return;
      }

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCreationPage(
            email: user?.email ?? '',
            userUuid: user?.uid ?? '',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Une erreur s'est produite";
      debugPrint(message);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint("Erreur inconnue : $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur inconnue.")),
      );
    }
  }


  // Future<void> _signupUser(String email, String password) async {
  //   try {
  //     UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //
  //     final user = userCredential.user;
  //     if (user != null && !user.emailVerified) {
  //       await user.sendEmailVerification();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("📧 Un email de vérification a été envoyé.")),
  //       );
  //     }
  //
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ProfileCreationPage(
  //           email: user?.email ?? '',
  //           userUuid: user?.uid ?? '',
  //         ),
  //       ),
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     String message = e.message ?? "Une erreur s'est produite";
  //     debugPrint(message);
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  //   } catch (e) {
  //     debugPrint("Erreur inconnue : $e");
  //   }
  // }

  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
    if (!EmailValidator.validate(email)) return 'Format d\'email invalide.';
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
// import '../profil/profil_creation_page.dart';
//
// class SigninPage extends StatefulWidget {
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
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Ajout de la clé pour la validation
//   bool isPasswordVisible = false;
//   bool isLoading = false; // Pour l'indicateur de chargement
//
//   @override
//   Widget build(BuildContext context) {
//     myColor = Theme.of(context).primaryColor;
//
//     return Scaffold(
//       backgroundColor: myColor,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: 80,
//               left: 0,
//               right: 0,
//               child: _buildTop(),
//             ),
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: _buildBottom(),
//             ),
//             if (isLoading)
//               const Center(
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTop() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(
//           Icons.location_on_sharp,
//           size: 100,
//           color: Colors.white,
//         ),
//         const Text(
//           "Hairbnb",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 40,
//             letterSpacing: 2,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBottom() {
//     return Card(
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(30),
//           topRight: Radius.circular(30),
//         ),
//       ),
//       margin: EdgeInsets.zero,
//       child: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: _buildForm(),
//           ),
//         ),
//       ),
//     );
//   }
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
//         const SizedBox(height: 30),
//         _buildGreyText("Adresse e-mail"),
//         _buildInputField(
//           controller: emailController,
//           hintText: "Entrez votre email",
//           validator: validateEmail,
//         ),
//         const SizedBox(height: 20),
//         _buildGreyText("Mot de passe"),
//         _buildInputField(
//           controller: passwordController,
//           hintText: "Entrez votre mot de passe",
//           isPassword: true,
//           validator: validatePassword,
//         ),
//         const SizedBox(height: 20),
//         _buildGreyText("Confirmez le mot de passe"),
//         _buildInputField(
//           controller: confirmPasswordController,
//           hintText: "Confirmez votre mot de passe",
//           isPassword: true,
//           validator: validatePasswords,
//         ),
//         const SizedBox(height: 30),
//         _buildSigninButton(),
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
//   Widget _buildInputField({
//     required TextEditingController controller,
//     required String hintText,
//     required String? Function(String?) validator,
//     bool isPassword = false,
//   }) {
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
//   Widget _buildSigninButton() {
//     return ElevatedButton(
//       onPressed: () async {
//         if (_formKey.currentState!.validate()) {
//           setState(() => isLoading = true);
//           await _signupUser(emailController.text, passwordController.text);
//           setState(() => isLoading = false);
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
//   Future<void> _signupUser(String email, String password) async {
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Récupérer l'UID et l'email
//       String userEmail = userCredential.user?.email ?? "";
//       String userUID = userCredential.user?.uid ?? "";
//
//       debugPrint("Utilisateur inscrit : Email = $userEmail, UID = $userUID");
//
//       // Redirection vers la page de création de profil avec les données de l'utilisateur
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProfileCreationPage(
//             email: userEmail,
//             userUuid: userUID,
//           ),
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       String message = e.message ?? "Une erreur s'est produite";
//       debugPrint(message);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     } catch (e) {
//       debugPrint("Erreur inconnue : $e");
//     }
//   }
//
//   String? validateEmail(String? email) {
//     if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
//     final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
//     if (!emailRegex.hasMatch(email)) return 'Format d\'email invalide.';
//     return null;
//   }
//
//   String? validatePassword(String? password) {
//     if (password == null || password.isEmpty) return 'Veuillez entrer un mot de passe.';
//     if (password.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères.';
//     return null;
//   }
//
//   String? validatePasswords(String? confirmPassword) {
//     if (confirmPassword != passwordController.text) {
//       return 'Les mots de passe ne correspondent pas.';
//     }
//     return null;
//   }
// }