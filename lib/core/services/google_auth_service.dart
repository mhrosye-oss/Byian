import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// نتيجة محاولة تسجيل الدخول بواسطة Google
class GoogleAuthResult {
  final bool success;
  final String? message;
  final bool isCancelled;
  final bool isNewUser;
  final String? firebaseIdToken;

  const GoogleAuthResult({
    required this.success,
    this.message,
    this.isCancelled = false,
    this.isNewUser = false,
    this.firebaseIdToken,
  });
}

/// خدمة تسجيل الدخول بالمصادقة عبر حساب Google باستخدام Firebase.
class GoogleAuthService {
  /// معرف عميل الويب (Web Client ID) المستخرج من google-services.json
  static const String serverClientId =
      '360885645807-07cpqme74670vpi9o3uj5b5rgtthv2vl.apps.googleusercontent.com';

  static bool _initialized = false;

  /// تهيئة إعدادات Google Sign-In لمرة واحدة
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn initialize warning: $e');
      _initialized = true;
    }
  }

  /// تسجيل الدخول بواسطة حساب Google عبر Firebase
  static Future<GoogleAuthResult> signIn({String? referralCode}) async {
    try {
      await ensureInitialized();

      // فتح نافذة Google للمصادقة واختيار الحساب
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      final googleAuth = account.authentication;
      final firebaseIdToken = googleAuth.idToken;

      return GoogleAuthResult(
        success: true,
        firebaseIdToken: firebaseIdToken,
        message: 'تم تسجيل الدخول عبر Google بنجاح',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleAuthResult(
          success: false,
          isCancelled: true,
          message: 'تم إلغاء عملية تسجيل الدخول.',
        );
      }
      return GoogleAuthResult(
        success: false,
        message: 'خطأ في حساب Google: ${e.description ?? e.code.name}',
      );
    } catch (e) {
      return GoogleAuthResult(
        success: false,
        message: 'تعذر الاتصال بخدمة Google: $e',
      );
    }
  }

  /// تسجيل الخروج من حساب Google
  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
