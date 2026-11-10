import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Generated from the user-provided Android Firebase configuration.
/// Firebase client identifiers are public app configuration, not server secrets.
/// The source google-services.json remains local and is excluded from Git.
abstract final class CircleFirebaseOptions {
  static const googleServerClientId =
      "360885645807-07cpqme74670vpi9o3uj5b5rgtthv2vl.apps.googleusercontent.com";

  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Firebase is configured for Android only. Add the iOS plist before using Circles on iOS.',
    );
  }

  static const android = FirebaseOptions(
    apiKey: "AIzaSyBLjodXJlCaw0iwtkWLkIzwRpdORME_zE0",
    appId: "1:360885645807:android:3b69347fec377c21cac61a",
    messagingSenderId: "360885645807",
    projectId: "dr-honey-b1dc5",
    storageBucket: "dr-honey-b1dc5.firebasestorage.app",
  );
}
