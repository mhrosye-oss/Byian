import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.initialize();
}

/// Android FCM client helpers. The current backend has no route for registering
/// Firebase Installation IDs, so this service deliberately does not upload them.
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  static void registerBackgroundHandler() {
    if (FirebaseBootstrap.isConfiguredPlatform) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
    }
  }

  Future<String?> requestPermissionAndRegister() async {
    if (!FirebaseBootstrap.isConfiguredPlatform) {
      throw UnsupportedError('إشعارات Firebase غير مهيأة لهذه المنصة بعد.');
    }

    await FirebaseBootstrap.initialize();
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return null;
    }
    final registeredId = FirebaseMessaging.instance.onRegistered.first.timeout(
      const Duration(seconds: 15),
      onTimeout: () => '',
    );
    await FirebaseMessaging.instance.register();
    final id = await registeredId;
    return id.isEmpty ? null : id;
  }

  Stream<String> get onRegistered => FirebaseMessaging.instance.onRegistered;

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
