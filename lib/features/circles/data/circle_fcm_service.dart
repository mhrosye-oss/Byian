import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'circle_api_client.dart';
import 'circle_auth_service.dart';
import 'circle_firebase_options.dart';

@pragma('vm:entry-point')
Future<void> circleFirebaseBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty &&
      defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
        options: CircleFirebaseOptions.currentPlatform);
  }
}

class CircleFcmService {
  CircleFcmService._();

  static final CircleFcmService instance = CircleFcmService._();
  static const _channel = AndroidNotificationChannel(
    'itqan_circle_updates',
    'إشعارات الدوائر',
    description: 'تنبيهات المهام والدوائر والهمسات',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<List<RemoteMessage>> recentMessages =
      ValueNotifier<List<RemoteMessage>>(const []);
  final StreamController<RemoteMessage> _notificationTaps =
      StreamController<RemoteMessage>.broadcast();
  final Map<int, RemoteMessage> _localMessageById = <int, RemoteMessage>{};
  StreamSubscription<String>? _tokenRefresh;
  bool _localNotificationsReady = false;
  bool _listenersRegistered = false;
  String? _registeredToken;

  Stream<RemoteMessage> get notificationTaps => _notificationTaps.stream;

  static void registerBackgroundHandler() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      FirebaseMessaging.onBackgroundMessage(circleFirebaseBackgroundHandler);
    }
  }

  Future<void> registerAfterLogin(CircleApiClient api) async {
    if (kIsWeb || !CircleFirebaseAuthService.instance.isSupported) return;
    await CircleFirebaseAuthService.instance.initialize();
    registerBackgroundHandler();
    _registerMessageHandlers();
    await _initializeLocalNotifications();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await api.registerPushInstallation(
      installationId: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
    _registeredToken = token;

    await _tokenRefresh?.cancel();
    _tokenRefresh = FirebaseMessaging.instance.onTokenRefresh.listen((value) {
      unawaited(_registerRefreshedToken(api, value));
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _recordAndOpen(initialMessage);
  }

  Future<void> unregisterBeforeLogout(CircleApiClient api) async {
    try {
      if (Firebase.apps.isNotEmpty &&
          CircleFirebaseAuthService.instance.isSupported) {
        final token =
            _registeredToken ?? await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await api.unregisterPushInstallation(token);
        }
      }
    } catch (_) {
      // Push cleanup must not prevent the user from signing out.
    }
    _registeredToken = null;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    if (Firebase.apps.isNotEmpty &&
        CircleFirebaseAuthService.instance.isSupported) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // The API session can still be cleared if FCM is temporarily offline.
      }
    }
  }

  void _registerMessageHandlers() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;
    FirebaseMessaging.onMessageOpenedApp.listen(_recordAndOpen);
    FirebaseMessaging.onMessage.listen((message) {
      _record(message);
      unawaited(_showForegroundNotification(message));
    });
  }

  void _record(RemoteMessage message) {
    final current = recentMessages.value;
    recentMessages.value =
        [message, ...current].take(50).toList(growable: false);
  }

  void _recordAndOpen(RemoteMessage message) {
    _record(message);
    if (!_notificationTaps.isClosed) _notificationTaps.add(message);
  }

  Future<void> _registerRefreshedToken(
    CircleApiClient api,
    String token,
  ) async {
    try {
      await api.registerPushInstallation(
        installationId: token,
        platform:
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
      _registeredToken = token;
    } catch (_) {
      // A later token refresh or next sign-in retries registration.
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (response) {
        final message =
            response.id == null ? null : _localMessageById.remove(response.id);
        if (message != null) _recordAndOpen(message);
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _localNotificationsReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final notificationId = notification.hashCode;
    _localMessageById[notificationId] = message;
    await _localNotifications.show(
      notificationId,
      notification.title ?? 'إتقان',
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'itqan_circle_updates',
          'إشعارات الدوائر',
          channelDescription: 'تنبيهات المهام والدوائر والهمسات',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['template']?.toString(),
    );
  }
}
