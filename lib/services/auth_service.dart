import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Web & Mobile uyumlu Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Kesin güvence: Firebase henüz ayağa kalkmadıysa burada başlat
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobil ortamlar için pop-up veya provider fallback
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithProvider(googleProvider);
      }
    } catch (e) {
      debugPrint('Google Sign-In hatası: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
