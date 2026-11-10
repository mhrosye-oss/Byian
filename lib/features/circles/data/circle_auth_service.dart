import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/circle_models.dart';
import 'circle_api_client.dart';
import 'circle_firebase_options.dart';

class CircleFirebaseAuthService {
  CircleFirebaseAuthService._();

  static final CircleFirebaseAuthService instance =
      CircleFirebaseAuthService._();
  static Future<void>? _initializeFuture;

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!isSupported) {
      throw UnsupportedError(
        'تسجيل الدخول عبر Firebase متاح بعد إعداد ملف Firebase لهذه المنصة.',
      );
    }
    if (Firebase.apps.isEmpty) {
      _initializeFuture ??= Firebase.initializeApp(
        options: CircleFirebaseOptions.currentPlatform,
      );
      await _initializeFuture;
    }
  }

  Future<String?> signInAndGetFirebaseIdToken() async {
    await initialize();
    final google = GoogleSignIn(
      serverClientId: CircleFirebaseOptions.googleServerClientId,
      scopes: const ['email', 'profile'],
    );
    final account = await google.signIn();
    if (account == null) return null;

    final googleAuthentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuthentication.accessToken,
      idToken: googleAuthentication.idToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final token = await result.user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('لم تُرجع Firebase رمز هوية صالحًا.');
    }
    return token;
  }

  Future<AppUser?> loginWithGoogle(CircleApiClient api) async {
    final firebaseIdToken = await signInAndGetFirebaseIdToken();
    if (firebaseIdToken == null) return null;
    return api.exchangeFirebaseIdToken(firebaseIdToken);
  }

  Future<void> signOut() async {
    if (!isSupported || Firebase.apps.isEmpty) return;
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      await GoogleSignIn(
        serverClientId: CircleFirebaseOptions.googleServerClientId,
      ).signOut();
    }
  }
}
