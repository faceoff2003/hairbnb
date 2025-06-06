import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profil/profil_creation_page.dart';
import 'authentification_services_pages/email_not_verified.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage>
    with TickerProviderStateMixin {
  late Size mediaSize;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  bool isPasswordValid = false;
  bool isConfirmPasswordValid = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Couleurs modernes inspirées des designs
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color secondaryOrange = Color(0xFFFF7675);
  static const Color lightPurple = Color(0xFFA29BFE);
  static const Color darkText = Color(0xFF2D3436);
  static const Color lightGrey = Color(0xFF636E72);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  bool isAndroidDevice() => kIsWeb ? false : Platform.isAndroid;

  // Validation avancée du mot de passe
  bool _validatePassword(String password) {
    if (password.isEmpty) return false;

    // Au moins 6 caractères
    if (password.length < 6) return false;

    // Au moins une majuscule
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Au moins une minuscule
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Au moins un chiffre
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // Au moins un caractère spécial (+, -, *, @, !, #, $, %, &)
    if (!password.contains(RegExp(r'[+\-*@!#$%&]'))) return false;

    return true;
  }

  String? _getPasswordErrorMessage(String password) {
    if (password.isEmpty) return 'Ce champ est requis';

    List<String> errors = [];

    if (password.length < 6) {
      errors.add('6 caractères minimum');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('1 majuscule');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('1 minuscule');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('1 chiffre');
    }
    if (!password.contains(RegExp(r'[+\-*@!#$%&]'))) {
      errors.add('1 caractère spécial (+,-,*,@,!,#,%,&)');
    }

    if (errors.isNotEmpty) {
      return 'Requis: ${errors.join(', ')}';
    }

    return null;
  }

  // Déterminer le type d'écran pour la responsivité
  bool get isLargeScreen => mediaSize.width >= 768;
  bool get isSmallScreen => mediaSize.width < 768;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Ajouter des listeners pour la validation en temps réel
    passwordController.addListener(() {
      setState(() {
        isPasswordValid = _validatePassword(passwordController.text);
      });
    });

    confirmPasswordController.addListener(() {
      setState(() {
        isConfirmPasswordValid = confirmPasswordController.text.isNotEmpty &&
            confirmPasswordController.text == passwordController.text;
      });
    });

    // Démarrer les animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: _buildResponsiveLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    if (isLargeScreen) {
      return _buildLargeScreenLayout();
    } else {
      return _buildSmallScreenLayout();
    }
  }

  // Layout pour grands écrans (≥ 768px) - Web
  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        // Panneau gauche avec branding
        Expanded(
          flex: 6,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryPurple, lightPurple, secondaryOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Motif décoratif
                Positioned.fill(
                  child: CustomPaint(
                    painter: GeometricPatternPainter(),
                  ),
                ),
                // Contenu centré
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWebBranding(),
                      const SizedBox(height: 40),
                      _buildFeaturesList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Panneau droit avec formulaire
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: _buildSignupForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout pour petits écrans (< 768px) - Mobile
  Widget _buildSmallScreenLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            SizedBox(height: mediaSize.height * 0.05),
            _buildMobileHeader(),
            SizedBox(height: mediaSize.height * 0.05),
            _buildSignupCard(),
          ],
        ),
      ),
    );
  }

  // Branding pour web
  Widget _buildWebBranding() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Hairbnb',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Rejoignez notre communauté\nde coiffeurs et clients',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Liste des fonctionnalités pour web
  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.account_circle, 'text': 'Profil personnalisé'},
      {'icon': Icons.security, 'text': 'Données sécurisées'},
      {'icon': Icons.notifications, 'text': 'Notifications temps réel'},
      {'icon': Icons.support_agent, 'text': 'Support 24/7'},
    ];

    return Column(
      children: features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              feature['text'] as String,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        // Logo moderne avec gradient
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [primaryPurple, lightPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.3),
                offset: const Offset(0, 10),
                blurRadius: 25,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        // Titre avec style moderne
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [primaryPurple, secondaryOrange],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Hairbnb',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Rejoignez notre communauté',
          style: TextStyle(
            fontSize: 14,
            color: lightGrey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isSmallScreen ? [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildSignupForm(),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du formulaire
          Text(
            'Inscription',
            style: TextStyle(
              fontSize: isLargeScreen ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre compte gratuitement',
            style: TextStyle(
              fontSize: isLargeScreen ? 18 : 16,
              color: lightGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isLargeScreen ? 40 : 32),

          // Champ email moderne
          _buildModernInputField(
            controller: emailController,
            label: 'Email',
            hint: 'votre.email@exemple.com',
            icon: Icons.email_outlined,
            isEmail: true,
          ),
          SizedBox(height: isLargeScreen ? 24 : 20),

          // Champ mot de passe moderne
          _buildModernInputField(
            controller: passwordController,
            label: 'Mot de passe',
            hint: 'Créez un mot de passe sécurisé',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          SizedBox(height: isLargeScreen ? 24 : 20),

          // Champ confirmation mot de passe moderne
          _buildModernInputField(
            controller: confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: 'Répétez votre mot de passe',
            icon: Icons.lock_outline,
            isConfirmPassword: true,
          ),
          SizedBox(height: isLargeScreen ? 32 : 24),

          // Bouton d'inscription moderne
          _buildModernSignupButton(),
          SizedBox(height: isLargeScreen ? 24 : 20),

          // Lien de connexion
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeScreen ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        SizedBox(height: isLargeScreen ? 12 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBorderColor(isPassword, isConfirmPassword),
              width: _getBorderWidth(isPassword, isConfirmPassword),
            ),
            color: Colors.grey.shade50,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: (isPassword && !isPasswordVisible) ||
                (isConfirmPassword && !isConfirmPasswordVisible),
            keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              fontSize: isLargeScreen ? 18 : 16,
              color: darkText,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (isEmail) {
                return _validateEmail(value);
              } else if (isPassword) {
                final errorMessage = _getPasswordErrorMessage(value ?? '');
                return errorMessage;
              } else if (isConfirmPassword) {
                return _validateConfirmPassword(value);
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isLargeScreen ? 18 : 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: primaryPurple,
                size: isLargeScreen ? 24 : 22,
              ),
              suffixIcon: _buildSuffixIcon(isPassword, isConfirmPassword),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isLargeScreen ? 24 : 20),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(bool isPassword, bool isConfirmPassword) {
    if (isPassword && passwordController.text.isNotEmpty && isPasswordValid) {
      return Colors.green;
    }
    if (isConfirmPassword && confirmPasswordController.text.isNotEmpty && isConfirmPasswordValid) {
      return Colors.green;
    }
    return Colors.grey.shade200;
  }

  double _getBorderWidth(bool isPassword, bool isConfirmPassword) {
    if ((isPassword && passwordController.text.isNotEmpty && isPasswordValid) ||
        (isConfirmPassword && confirmPasswordController.text.isNotEmpty && isConfirmPasswordValid)) {
      return 2.0;
    }
    return 1.0;
  }

  Widget? _buildSuffixIcon(bool isPassword, bool isConfirmPassword) {
    if (isPassword || isConfirmPassword) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de validation
          if ((isPassword && passwordController.text.isNotEmpty) ||
              (isConfirmPassword && confirmPasswordController.text.isNotEmpty))
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getValidationIconColor(isPassword, isConfirmPassword),
                border: Border.all(
                  color: _getValidationIconColor(isPassword, isConfirmPassword),
                  width: 2,
                ),
              ),
              child: _shouldShowCheckIcon(isPassword, isConfirmPassword)
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
          IconButton(
            icon: Icon(
              _getVisibilityIcon(isPassword, isConfirmPassword),
              color: lightGrey,
            ),
            onPressed: () => setState(() {
              if (isPassword) {
                isPasswordVisible = !isPasswordVisible;
              } else if (isConfirmPassword) {
                isConfirmPasswordVisible = !isConfirmPasswordVisible;
              }
            }),
          ),
        ],
      );
    }
    return null;
  }

  Color _getValidationIconColor(bool isPassword, bool isConfirmPassword) {
    if (isPassword && isPasswordValid) return Colors.green;
    if (isConfirmPassword && isConfirmPasswordValid) return Colors.green;
    return Colors.transparent;
  }

  bool _shouldShowCheckIcon(bool isPassword, bool isConfirmPassword) {
    if (isPassword && isPasswordValid) return true;
    if (isConfirmPassword && isConfirmPasswordValid) return true;
    return false;
  }

  IconData _getVisibilityIcon(bool isPassword, bool isConfirmPassword) {
    if (isPassword) {
      return isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined;
    } else if (isConfirmPassword) {
      return isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined;
    }
    return Icons.visibility_off_outlined;
  }

  Widget _buildModernSignupButton() {
    return Container(
      width: double.infinity,
      height: isLargeScreen ? 64 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [primaryPurple, lightPurple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : _handleSignup,
          child: Center(
            child: isLoading
                ? SizedBox(
              width: isLargeScreen ? 28 : 24,
              height: isLargeScreen ? 28 : 24,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              'S\'inscrire',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeScreen ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: RichText(
          text: TextSpan(
            text: 'Déjà un compte ? ',
            style: TextStyle(
              color: lightGrey,
              fontSize: isLargeScreen ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Se connecter',
                style: TextStyle(
                  color: primaryPurple,
                  fontSize: isLargeScreen ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes de validation
  String? _validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Ce champ est requis';
    if (!EmailValidator.validate(email)) return 'Format d\'email invalide';
    return null;
  }

  String? _validateConfirmPassword(String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) return 'Ce champ est requis';
    if (confirmPassword != passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    // Nettoyer les espaces et vérifier la validation
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Vérifier que les champs ne sont pas vides après nettoyage
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (!context.mounted) return;

        // Redirection vers EmailNotVerifiedPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailNotVerifiedPage(email: email),
          ),
        );
        return;
      }

      if (!context.mounted) return;

      // Si l'email est déjà vérifié, on va directement à la création de profil
      Navigator.pushReplacement(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Erreur inconnue : $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur inconnue."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}

// Painter pour les motifs géométriques décoratifs
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Dessiner des cercles décoratifs
    for (int i = 0; i < 20; i++) {
      final x = (i * 100.0) % size.width;
      final y = (i * 80.0) % size.height;
      final radius = 20.0 + (i % 3) * 10.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Dessiner des lignes diagonales
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    for (int i = 0; i < 10; i++) {
      final startX = i * (size.width / 10);
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + 100, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



// import 'package:email_validator/email_validator.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../profil/profil_creation_page.dart';
// import 'authentification_services_pages/email_not_verified.dart';
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
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool isPasswordVisible = false;
//   bool isLoading = false;
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
//             Positioned(top: 80, left: 0, right: 0, child: _buildTop()),
//             Positioned(bottom: 0, left: 0, right: 0, child: _buildBottom()),
//             if (isLoading)
//               const Center(child: CircularProgressIndicator()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTop() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: const [
//         Icon(Icons.location_on_sharp, size: 100, color: Colors.white),
//         Text(
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
//         Text("Bienvenue", style: TextStyle(color: myColor, fontSize: 32, fontWeight: FontWeight.w500)),
//         _buildGreyText("Veuillez vous inscrire avec vos informations"),
//         const SizedBox(height: 30),
//         _buildGreyText("Adresse e-mail"),
//         _buildInputField(controller: emailController, hintText: "Entrez votre email", validator: validateEmail),
//         const SizedBox(height: 20),
//         _buildGreyText("Mot de passe"),
//         _buildInputField(controller: passwordController, hintText: "Entrez votre mot de passe", isPassword: true, validator: validatePassword),
//         const SizedBox(height: 20),
//         _buildGreyText("Confirmez le mot de passe"),
//         _buildInputField(controller: confirmPasswordController, hintText: "Confirmez votre mot de passe", isPassword: true, validator: validatePasswords),
//         const SizedBox(height: 30),
//         _buildSigninButton(),
//       ],
//     );
//   }
//
//   Widget _buildGreyText(String text) => Text(text, style: const TextStyle(color: Colors.grey));
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
//           icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
//           onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
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
//           await _signupUser(emailController.text.trim(), passwordController.text);
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
//       final user = userCredential.user;
//       if (user != null && !user.emailVerified) {
//         await user.sendEmailVerification();
//
//         if (!context.mounted) return;
//
//         // Redirection vers EmailNotVerifiedPage au lieu d'afficher seulement un SnackBar
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => EmailNotVerifiedPage(email: email),
//           ),
//         );
//         return;
//       }
//
//       if (!context.mounted) return;
//
//       // Si l'email est déjà vérifié, on va directement à la création de profil
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProfileCreationPage(
//             email: user?.email ?? '',
//             userUuid: user?.uid ?? '',
//           ),
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       String message = e.message ?? "Une erreur s'est produite";
//       debugPrint(message);
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     } catch (e) {
//       debugPrint("Erreur inconnue : $e");
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur inconnue.")),
//       );
//     }
//   }
//
//   String? validateEmail(String? email) {
//     if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
//     if (!EmailValidator.validate(email)) return 'Format d\'email invalide.';
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





// import 'package:email_validator/email_validator.dart';
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
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool isPasswordVisible = false;
//   bool isLoading = false;
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
//             Positioned(top: 80, left: 0, right: 0, child: _buildTop()),
//             Positioned(bottom: 0, left: 0, right: 0, child: _buildBottom()),
//             if (isLoading)
//               const Center(child: CircularProgressIndicator()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTop() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: const [
//         Icon(Icons.location_on_sharp, size: 100, color: Colors.white),
//         Text(
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
//         Text("Bienvenue", style: TextStyle(color: myColor, fontSize: 32, fontWeight: FontWeight.w500)),
//         _buildGreyText("Veuillez vous inscrire avec vos informations"),
//         const SizedBox(height: 30),
//         _buildGreyText("Adresse e-mail"),
//         _buildInputField(controller: emailController, hintText: "Entrez votre email", validator: validateEmail),
//         const SizedBox(height: 20),
//         _buildGreyText("Mot de passe"),
//         _buildInputField(controller: passwordController, hintText: "Entrez votre mot de passe", isPassword: true, validator: validatePassword),
//         const SizedBox(height: 20),
//         _buildGreyText("Confirmez le mot de passe"),
//         _buildInputField(controller: confirmPasswordController, hintText: "Confirmez votre mot de passe", isPassword: true, validator: validatePasswords),
//         const SizedBox(height: 30),
//         _buildSigninButton(),
//       ],
//     );
//   }
//
//   Widget _buildGreyText(String text) => Text(text, style: const TextStyle(color: Colors.grey));
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
//           icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
//           onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
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
//           await _signupUser(emailController.text.trim(), passwordController.text);
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
//       final user = userCredential.user;
//       if (user != null && !user.emailVerified) {
//         await user.sendEmailVerification();
//
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("📧 Email de vérification envoyé. Veuillez vérifier votre boîte mail."),
//           ),
//         );
//
//         // 🔒 On ne redirige pas vers la suite tant que l'utilisateur n'a pas confirmé son email
//         return;
//       }
//
//       if (!context.mounted) return;
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProfileCreationPage(
//             email: user?.email ?? '',
//             userUuid: user?.uid ?? '',
//           ),
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       String message = e.message ?? "Une erreur s'est produite";
//       debugPrint(message);
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//     } catch (e) {
//       debugPrint("Erreur inconnue : $e");
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erreur inconnue.")),
//       );
//     }
//   }
//   String? validateEmail(String? email) {
//     if (email == null || email.isEmpty) return 'Veuillez entrer un email.';
//     if (!EmailValidator.validate(email)) return 'Format d\'email invalide.';
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