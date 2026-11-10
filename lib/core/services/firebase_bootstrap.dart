import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase on platforms with a checked-in client configuration.
/// Android is configured via android/app/google-services.json. iOS remains
/// disabled until GoogleService-Info.plist is added to the Runner target.
abstract final class FirebaseBootstrap {
  static bool get isConfiguredPlatform =>
      defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!isConfiguredPlatform || Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  }
}
