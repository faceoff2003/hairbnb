import 'package:flutter/material.dart';
import 'package:hairbnb/pages/signin_page.dart';
import 'package:hairbnb/services/auth_services/auth_service.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Color myColor;
  late Size mediaSize;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;

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
          colorFilter:
          ColorFilter.mode(myColor.withOpacity(0.2), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Permet au contenu de se redimensionner avec le clavier
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Ferme le clavier en appuyant à l'extérieur
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: mediaSize.height,
              ),
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

  Widget _buildTop() {
    return SizedBox(
      width: mediaSize.width,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_sharp,
            size: 100,
            color: Colors.white,
          ),
          Text(
            "Hairbnb",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
                letterSpacing: 2),
          )
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildForm(),
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
        _buildGreyText("Veuillez vous connecter avec vos informations"),
        const SizedBox(height: 60),
        _buildGreyText("Adresse e-mail"),
        _buildInputField(emailController),
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
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {isPassword = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        suffixIcon: isPassword
            ? const Icon(Icons.remove_red_eye)
            : const Icon(Icons.done),
      ),
      obscureText: isPassword,
    );
  }

  Widget _buildRememberForgot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: rememberUser,
                  onChanged: (value) {
                    setState(() {
                      rememberUser = value!;
                    });
                  },
                ),
                _buildGreyText("Souviens-toi de moi"),
              ],
            ),
            TextButton(
              onPressed: () {}, // Ajouter une fonction pour le mot de passe oublié
              child: _buildGreyText("MP oublié"),
            )
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SigninPage(),
                ),
              );
            },
            child: _buildGreyText("Créer votre compte"),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () {
        AuthService().loginUserWithEmailandPassword(
            emailController.text, passwordController.text,
            context, emailController, passwordController);
        debugPrint("++++++++vous avez appuyer de le bouton connexion email+mp+++++++++++++");
      },
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        elevation: 20,
        shadowColor: myColor,
        minimumSize: const Size.fromHeight(60),
      ),
      child: const Text("Connexion"),
    );
  }

  Widget _buildOtherLogin() {
    return Center(
      child: Column(
        children: [
          _buildGreyText("Ou se connecter avec"),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tab(icon: Image.asset("assets/logo_login/facebook.png")),
              GestureDetector(
                onTap: () async {
                    final user = await AuthService().loginWithGoogle(context);
                      //Navigator.pushReplacementNamed(context, '/home');
                      print("///////////////${user!.uid}///////////////////");
                },
                child: SizedBox(
                  width: 40, // Taille personnalisée
                  height: 40,
                  child: Image.asset(
                    "assets/logo_login/google.png",
                    fit: BoxFit.contain, // Ajuste l'image
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}
