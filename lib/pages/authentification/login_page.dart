import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hairbnb/pages/authentification/signup_page.dart';
import 'authentification_services_pages/login_with_email.dart';
import 'authentification_services_pages/login_with_google.dart';
import 'authentification_services_pages/reset_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Color myColor;
  late Size mediaSize;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool rememberUser = false;
  bool isPasswordVisible = false;

  bool isAndroidDevice() => kIsWeb ? false : Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;
    mediaSize = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
          image: const AssetImage("assets/logo_login/bg.png"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(myColor.withOpacity(0.2), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: mediaSize.height),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Positioned(top: 80, child: _buildTop()),
                    Positioned(bottom: 0, child: _buildBottom()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTop() => SizedBox(
    width: mediaSize.width,
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_sharp, size: 100, color: Colors.white),
        Text("Hairbnb", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    ),
  );

  Widget _buildBottom() => SizedBox(
    width: mediaSize.width,
    child: Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: _buildForm(),
      ),
    ),
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bienvenue", style: TextStyle(color: myColor, fontSize: 32, fontWeight: FontWeight.w500)),
        _buildGreyText("Veuillez vous connecter avec vos informations"),
        const SizedBox(height: 60),
        _buildGreyText("Adresse e-mail"),
        _buildInputField(emailController, isEmail: true),
        const SizedBox(height: 40),
        _buildGreyText("Mot de passe"),
        _buildInputField(passwordController, isPassword: true),
        const SizedBox(height: 20),
        _buildRememberForgot(),
        const SizedBox(height: 20),
        _buildLoginButton(),
        const SizedBox(height: 20),
        _buildOtherLogin(),
      ],
    ),
  );

  Widget _buildGreyText(String text) => Text(text, style: const TextStyle(color: Colors.grey));

  Widget _buildInputField(TextEditingController controller, {bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est requis';
        if (isEmail && !EmailValidator.validate(value)) return 'Format d\'email invalide';
        if (isPassword && value.length < 6) return 'Mot de passe trop court';
        return null;
      },
      decoration: InputDecoration(
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
        )
            : null,
      ),
    );
  }

  Widget _buildRememberForgot() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!isAndroidDevice())
        Row(
          children: [
            Checkbox(
              value: rememberUser,
              onChanged: (value) => setState(() => rememberUser = value!),
            ),
            _buildGreyText("Souviens-toi de moi"),
          ],
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => showResetPasswordDialog(context),
            child: _buildGreyText("Mot de passe oublié ?"),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SigninPage()),
            ),
            child: _buildGreyText("Créer votre compte"),
          ),
        ],
      ),
    ],
  );

  Widget _buildLoginButton() => ElevatedButton(
    onPressed: () async {
      //if (_formKey.currentState!.validate()) {
        await loginWithEmail(
          context,
          emailController.text.trim(),
          passwordController.text.trim(),
          emailController: emailController,
          passwordController: passwordController,
        );
      //}
    },

    style: ElevatedButton.styleFrom(
      shape: const StadiumBorder(),
      elevation: 20,
      shadowColor: myColor,
      minimumSize: const Size.fromHeight(60),
    ),
    child: const Text("Connexion"),
  );

  Widget _buildOtherLogin() => Center(
    child: Column(
      children: [
        _buildGreyText("Ou se connecter avec"),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final user = await loginWithGoogle(context);
            // if (user != null && context.mounted) {
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => ProfileCreationPage(
            //         email: user.email ?? '',
            //         userUuid: user.uid,
            //       ),
            //     ),
            //   );
            // }
          },
          child: MouseRegion(
            cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.asset("assets/logo_login/google.png", fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    ),
  );
}
