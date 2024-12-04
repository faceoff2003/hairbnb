import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Gère les authentifications avec Google et Facebook.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Authentifie un utilisateur avec son compte Google.
  ///
  /// Tente de lancer l'authentification avec un compte Google.
  /// Si l'utilisateur annule l'opération, ou si cela échoue, renvoie null.
  /// Sinon, renvoie l'objet [User] correspondant à l'utilisateur connecté.
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("Début de l'authentification Google.");
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint("Authentification annulée par l'utilisateur.");
        return null; // L'utilisateur a annulé l'opération.
      }
      debugPrint("Utilisateur Google sélectionné : ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint("Jetons récupérés : idToken = ${googleAuth.idToken}, accessToken = ${googleAuth.accessToken}");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("Utilisateur connecté avec succès : ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      debugPrint("Erreur lors de Google Sign-In : $e");
      rethrow;
    }
  }



  /// Authentifie un utilisateur avec son compte Facebook.
  ///
  /// Tente de lancer l'authentification avec un compte Facebook.
  /// Si l'utilisateur annule l'opération, ou si cela échoue, renvoie null.
  /// Sinon, renvoie l'objet [User] correspondant à l'utilisateur connecté.
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
        UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        return userCredential.user;
      } else {
        debugPrint("Facebook login annulé ou échoué: ${loginResult.status}");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur lors de l'authentification Facebook: $e");
      rethrow;
    }
  }
}
