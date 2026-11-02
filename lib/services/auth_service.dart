import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  static const _iosClientId =
      '1060637668034-pj0jrl8l6kt8616mq88cj8gv08kido09.apps.googleusercontent.com';

  final GoogleSignIn? _googleSignIn = kIsWeb
      ? null
      : GoogleSignIn(
          clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,
        );



  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> login(String email, String password) async {
    var result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> register(String email, String password) async {
    var result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null; // User canceled

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }


  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}