import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google ಸೈನ್-ಇನ್ + Firebase Auth — ವೆಬ್‌ನಂತೆಯೇ.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get user => _auth.currentUser;

  /// ರದ್ದಾದರೆ null ಹಿಂತಿರುಗಿಸುತ್ತದೆ.
  Future<User?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null; // ಬಳಕೆದಾರ ರದ್ದುಮಾಡಿದರು
    final auth = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    final res = await _auth.signInWithCredential(cred);
    return res.user;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
