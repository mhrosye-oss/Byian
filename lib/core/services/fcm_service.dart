import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

const String _notificationChannelId = 'itqan_messages_v1';
const String _notificationChannelName = 'إشعارات إتقان';
const String _notificationChannelDescription = 'إشعارات وتذكيرات تطبيق إتقان';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  // Notification payloads are displayed by Android itself in the background.
  // Data-only payloads need a local notification to be visible to the user.
  if (message.notification == null) {
    await FcmService.showMessage(message);
  }
}

class FcmService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://blueviolet-viper-439935.hostingersite.com',
  );
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initialization;
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _localNotificationsInitialized = false;
  static void Function(Map<String, dynamic>)? _notificationTapHandler;
  static Map<String, dynamic>? _pendingNotificationTap;

  static Future<void> initialize() {
    final active = _initialization;
    if (active != null) return active;

    late final Future<void> task;
    task = _initialize().catchError((Object error) {
      if (identical(_initialization, task)) _initialization = null;
      Error.throwWithStackTrace(error, StackTrace.current);
    });
    _initialization = task;
    return task;
  }

  static Future<void> _initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    _messageSubscription ??= FirebaseMessaging.onMessage.listen(
      showMessage,
      onError: (Object error) =>
          debugPrint('FCM foreground message handling failed: $error'),
    );
    _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleRemoteNotificationTap,
      onError: (Object error) =>
          debugPrint('FCM notification tap handling failed: $error'),
    );
    _tokenRefreshSubscription ??=
        // The FCM registration token, unlike the new FID event, is required
        // by the backend's existing installation_id contract.
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerRefreshedToken,
      onError: (Object error) =>
          debugPrint('FCM token refresh listener failed: $error'),
    );
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteNotificationTap(initialMessage);
    }
  }

  static void setNotificationTapHandler(
    void Function(Map<String, dynamic>) handler,
  ) {
    _notificationTapHandler = handler;
    final pending = _pendingNotificationTap;
    if (pending != null) {
      _pendingNotificationTap = null;
      handler(pending);
    }
  }

  static void _handleRemoteNotificationTap(RemoteMessage message) {
    _dispatchNotificationTap(Map<String, dynamic>.from(message.data));
  }

  static void _handleLocalNotificationTap(
    NotificationResponse response,
  ) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _dispatchNotificationTap(Map<String, dynamic>.from(decoded));
      }
    } on FormatException catch (error) {
      debugPrint('Invalid FCM notification payload: $error');
    }
  }

  static void _dispatchNotificationTap(Map<String, dynamic> data) {
    final handler = _notificationTapHandler;
    if (handler == null) {
      _pendingNotificationTap = data;
    } else {
      handler(data);
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _notificationChannelId,
        _notificationChannelName,
        description: _notificationChannelDescription,
        importance: Importance.high,
      ),
    );
    _localNotificationsInitialized = true;
    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && response != null) {
      _handleLocalNotificationTap(response);
    }
  }

  static Future<bool> registerCurrentDevice({
    String? authToken,
    bool requestPermission = true,
  }) async {
    final sessionToken = authToken ?? await AuthService.getToken();
    if (sessionToken == null || sessionToken.trim().isEmpty) return false;

    final messaging = FirebaseMessaging.instance;
    final settings = requestPermission
        ? await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
        : await messaging.getNotificationSettings();
    if (!_canShowNotifications(settings.authorizationStatus)) return false;

    // getToken returns the FCM registration token expected by the push API.
    // Firebase Messaging 17's register/onRegistered API exposes an FID instead.
    // ignore: deprecated_member_use
    final installationId = await messaging.getToken();
    if (installationId == null || installationId.trim().isEmpty) {
      throw const HttpException('Firebase did not provide an FCM token.');
    }

    await _registerInstallation(
      installationId: installationId,
      authToken: sessionToken,
    );
    return true;
  }

  static bool _canShowNotifications(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static Future<void> _registerRefreshedToken(String installationId) async {
    final sessionToken = await AuthService.getToken();
    if (sessionToken == null || sessionToken.trim().isEmpty) return;
    try {
      await _registerInstallation(
        installationId: installationId,
        authToken: sessionToken,
      );
    } catch (error) {
      debugPrint('FCM refreshed token registration failed: $error');
    }
  }

  static Future<void> _registerInstallation({
    required String installationId,
    required String authToken,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/me/push-installations'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'installation_id': installationId,
            'platform': Platform.isIOS ? 'ios' : 'android',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'FCM registration failed with status ${response.statusCode}.',
      );
    }
  }

  static Future<void> showMessage(RemoteMessage message) async {
    await _initializeLocalNotifications();
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        message.data['notification_title']?.toString() ??
        'إتقان';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString();
    if (body == null || body.trim().isEmpty) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: _notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
