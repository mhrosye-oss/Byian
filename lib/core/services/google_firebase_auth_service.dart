import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

/// Performs native Google sign-in and Firebase Auth credential exchange.
///
/// The returned Firebase ID token is not the application's API bearer token.
/// A backend endpoint must verify/exchange it before the app can use protected
/// API routes.
class GoogleFirebaseAuthService {
  GoogleFirebaseAuthService._();

  static final GoogleFirebaseAuthService instance =
      GoogleFirebaseAuthService._();
  static Future<void>? _googleInitialization;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<String> signInAndGetFirebaseIdToken() async {
    if (!FirebaseBootstrap.isConfiguredPlatform) {
      throw UnsupportedError(
        'تسجيل Google عبر Firebase غير مهيأ لهذه المنصة بعد.',
      );
    }

    await FirebaseBootstrap.initialize();
    _googleInitialization ??= _googleSignIn.initialize();
    await _googleInitialization;

    final account = await _googleSignIn.authenticate();
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw StateError('لم يُرجع Google رمز هوية صالحًا.');
    }

    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseIdToken = await result.user?.getIdToken();
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('لم تُرجع Firebase رمز هوية صالحًا.');
    }
    return firebaseIdToken;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }
}
