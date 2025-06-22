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

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  late Size mediaSize;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool rememberUser = false;
  bool isPasswordVisible = false;
  bool isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // New state variable for password validation display
  bool _isPasswordValid = false;

  // Couleurs modernes inspirées des designs
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color secondaryOrange = Color(0xFFFF7675);
  static const Color lightPurple = Color(0xFFA29BFE);
  static const Color darkText = Color(0xFF2D3436);
  static const Color lightGrey = Color(0xFF636E72);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color validGreen = Color(0xFF28A745); // Added for valid state

  bool isAndroidDevice() => kIsWeb ? false : Platform.isAndroid;

  // Déterminer le type d'écran pour la responsivité
  bool get isDesktop => mediaSize.width >= 1200;
  bool get isTablet => mediaSize.width >= 768 && mediaSize.width < 1200;
  bool get isMobile => mediaSize.width < 768;

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

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Add listener to password controller for real-time validation feedback
    passwordController.addListener(_validatePasswordOnChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    emailController.dispose();
    passwordController.removeListener(_validatePasswordOnChanged); // Remove listener
    passwordController.dispose();
    super.dispose();
  }

  // Method to validate password and update _isPasswordValid
  void _validatePasswordOnChanged() {
    final password = passwordController.text;
    final isValid = _passwordRegex.hasMatch(password);
    if (_isPasswordValid != isValid) {
      setState(() {
        _isPasswordValid = isValid;
      });
    }
  }

  // Regex for strong password validation
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+=\-{}\[\]|;:"<>,./?`~])[A-Za-z\d!@#$%^&*()_+=\-{}\[\]|;:"<>,./?`~]{6,}$',
  );

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
    if (isDesktop) {
      return _buildDesktopLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // Layout pour desktop (≥ 1200px)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Panneau gauche avec image de fond et branding
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
                // CORRECTION 3: Contenu centré avec padding approprié
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center, // Ajouté pour centrer
                      children: [
                        _buildDesktopBranding(),
                        const SizedBox(height: 60), // Augmenté l'espace
                        _buildFeaturesList(),
                      ],
                    ),
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
            child: SingleChildScrollView( // CORRECTION 1: Ajout de SingleChildScrollView
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildLoginForm(isDesktop: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // Layout pour tablette (768px - 1199px)
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mediaSize.width * 0.1,
          vertical: 40,
        ),
        child: Column(
          children: [
            SizedBox(height: mediaSize.height * 0.05),
            _buildModernHeader(),
            SizedBox(height: mediaSize.height * 0.08),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _buildLoginCard(isTablet: true),
            ),
          ],
        ),
      ),
    );
  }

  // Layout pour mobile (< 768px)
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            SizedBox(height: mediaSize.height * 0.05),
            _buildModernHeader(),
            SizedBox(height: mediaSize.height * 0.05),
            _buildLoginCard(isMobile: true),
          ],
        ),
      ),
    );
  }

  // Branding pour desktop
  Widget _buildDesktopBranding() {
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
          'Trouvez votre coiffeur idéal\nen quelques clics',
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

  // Liste des fonctionnalités pour desktop
  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.search, 'text': 'Recherche avancée'},
      {'icon': Icons.star, 'text': 'Avis clients vérifiés'},
      {'icon': Icons.schedule, 'text': 'Réservation instantanée'},
      {'icon': Icons.favorite, 'text': 'Coiffeurs favoris'},
    ];

    return Center( // Centrer la colonne
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centrer verticalement
        crossAxisAlignment: CrossAxisAlignment.start, // Garder l'alignement des items à gauche
        children: features.map((feature) => Container(
          margin: const EdgeInsets.only(bottom: 20), // Augmenté l'espacement
          child: Row(
            mainAxisSize: MainAxisSize.min, // Prendre seulement l'espace nécessaire
            children: [
              Container(
                width: 45, // Légèrement plus grand
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 20), // Augmenté l'espace
              Text(
                feature['text'] as String,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18, // Augmenté la taille
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }


  Widget _buildModernHeader() {
    return Column(
      children: [
        // Logo moderne avec gradient
        Container(
          width: isMobile ? 80 : 100,
          height: isMobile ? 80 : 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 20 : 25),
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
          child: Icon(
            Icons.location_on_rounded,
            size: isMobile ? 40 : 50,
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
          child: Text(
            'Hairbnb',
            style: TextStyle(
              fontSize: isMobile ? 36 : 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trouvez votre coiffeur idéal',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: lightGrey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
      {bool isDesktop = false, bool isTablet = false, bool isMobile = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 24),
        boxShadow: isDesktop
            ? null
            : [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding:
        EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 32.0 : 24.0)),
        child: _buildLoginForm(isDesktop: isDesktop),
      ),
    );
  }

  Widget _buildLoginForm({bool isDesktop = false}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du formulaire
          Text(
            'Connexion',
            style: TextStyle(
              fontSize: isDesktop ? 32 : (isTablet ? 30 : 28),
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Heureux de vous revoir !',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: lightGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isDesktop ? 40 : 32),

          // Champ email moderne
          _buildModernInputField(
            controller: emailController,
            label: 'Email',
            hint: 'votre.email@exemple.com',
            icon: Icons.email_outlined,
            isEmail: true,
          ),
          SizedBox(height: isDesktop ? 24 : 20),

          // Champ mot de passe moderne
          _buildModernInputField(
            controller: passwordController,
            label: 'Mot de passe',
            hint: 'Entrez votre mot de passe',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          SizedBox(height: isDesktop ? 20 : 16),

          // Options et liens
          _buildModernOptions(),
          SizedBox(height: isDesktop ? 32 : 24),

          // Bouton de connexion moderne
          _buildModernLoginButton(),
          SizedBox(height: isDesktop ? 32 : 24),

          // Séparateur
          _buildDivider(),
          SizedBox(height: isDesktop ? 32 : 24),

          // Connexion avec Google
          _buildGoogleSignIn(),
          SizedBox(height: isDesktop ? 24 : 20),

          // Lien d'inscription
          _buildSignupLink(),
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
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
            border: Border.all(
              color: isPassword && _isPasswordValid
                  ? validGreen
                  : Colors.grey.shade200,
              width: 2,
            ),
            color: Colors.grey.shade50,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
            // CORRECTION 2: Gérer les actions du clavier
            textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: (value) {
              if (isPassword) {
                // Si c'est le champ mot de passe, déclencher la connexion
                _handleLogin();
              } else {
                // Si c'est l'email, passer au champ suivant
                FocusScope.of(context).nextFocus();
              }
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: darkText,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ce champ est requis';
              if (isEmail && !EmailValidator.validate(value)) {
                return 'Format d\'email invalide';
              }
              if (isPassword) {
                if (!_passwordRegex.hasMatch(value)) {
                  return 'Minimum 6 caractères, 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: primaryPurple,
                size: isDesktop ? 24 : 22,
              ),
              suffixIcon: isPassword
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: lightGrey,
                    ),
                    onPressed: () => setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    }),
                  ),
                  if (_isPasswordValid)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: validGreen,
                        size: isDesktop ? 24 : 22,
                      ),
                    ),
                ],
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isDesktop ? 24 : 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me checkbox (seulement sur non-Android et non-mobile)
        if (!isAndroidDevice() && !isMobile)
          GestureDetector(
            onTap: () => setState(() => rememberUser = !rememberUser),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: rememberUser ? primaryPurple : Colors.grey.shade300,
                      width: 2,
                    ),
                    color: rememberUser ? primaryPurple : Colors.transparent,
                  ),
                  child: rememberUser
                      ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Se souvenir',
                  style: TextStyle(
                    color: lightGrey,
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),

        // Mot de passe oublié
        GestureDetector(
          onTap: () => showResetPasswordDialog(context),
          child: Text(
            'Mot de passe oublié ?',
            style: TextStyle(
              color: primaryPurple,
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernLoginButton() {
    return Container(
      width: double.infinity,
      height: isDesktop ? 64 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
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
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
          onTap: isLoading ? null : _handleLogin,
          child: Center(
            child: isLoading
                ? SizedBox(
              width: isDesktop ? 28 : 24,
              height: isDesktop ? 28 : 24,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              'Se connecter',
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: lightGrey,
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignIn() {
    return Container(
      width: double.infinity,
      height: isDesktop ? 64 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        color: Colors.white,
        // Ajout d'une ombre subtile
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
          onTap: _handleGoogleLogin,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Ajout de padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CORRECTION 1: Image Google avec gestion d'erreur
                SizedBox(
                  width: isDesktop ? 28 : 24,
                  height: isDesktop ? 28 : 24,
                  child: Image.asset(
                    "assets/logo_login/google.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si l'image ne charge pas
                      return Container(
                        width: isDesktop ? 28 : 24,
                        height: isDesktop ? 28 : 24,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.g_mobiledata,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Flexible( // Utiliser Flexible au lieu de Text seul
                  child: Text(
                    'Continuer avec Google',
                    style: TextStyle(
                      color: darkText,
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis, // Gestion du débordement
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
              const SigninPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: RichText(
          text: TextSpan(
            text: 'Pas encore de compte ? ',
            style: TextStyle(
              color: lightGrey,
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'S\'inscrire',
                style: TextStyle(
                  color: primaryPurple,
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    setState(() => isLoading = true);

    try {
      // Assuming loginWithEmail returns true on success, false on failure
      final success = await loginWithEmail(
        context,
        emailController.text.trim(),
        passwordController.text.trim(),
        // Keep these if your loginWithEmail needs them, otherwise remove
        emailController: emailController,
        passwordController: passwordController,
      );

      if (success) {
        // Only clear if login was successful AND you are about to navigate
        emailController.clear();
        passwordController.clear();
        // You would typically navigate to your home page here
        // Example: Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show an error message if login was not successful
        // Example: ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Login failed. Please check your credentials.')),
        // );
      }
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final user = await loginWithGoogle(context);
      if (user != null) {
        // Traitement du succès de connexion Google (e.g., navigate to home)
        debugPrint('Google Login Successful: ${user.displayName}');
        // Example: Navigator.pushReplacementNamed(context, '/home');
      } else {
        debugPrint('Google Login Cancelled or Failed');
      }
    } catch (e) {
      debugPrint('Erreur de connexion Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion Google: ${e.toString()}')),
      );
    }
  }
}

// Painter pour les motifs géométriques décoratifs (no changes needed here)
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
