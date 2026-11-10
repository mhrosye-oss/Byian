import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'firebase_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.initialize();
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'itqan_notifications',
    'إشعارات إتقان',
    description: 'إشعارات الدوائر والتحديثات',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _registeredInstallationId;
  bool _initialized = false;

  static void registerBackgroundHandler() {
    if (FirebaseBootstrap.isConfiguredPlatform) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> initializeForegroundNotifications() async {
    if (_initialized || !FirebaseBootstrap.isConfiguredPlatform) return;
    _initialized = true;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: android),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<String?> registerAfterLogin() async {
    if (!FirebaseBootstrap.isConfiguredPlatform) return null;
    await FirebaseBootstrap.initialize();
    await initializeForegroundNotifications();
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return null;
    await _sendInstallation(token);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      unawaited(_sendInstallation(newToken));
    });
    return token;
  }

  Future<void> unregisterAfterLogout() async {
    final installationId = _registeredInstallationId;
    if (installationId != null) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final baseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://blueviolet-viper-439935.hostingersite.com',
        ).replaceAll(RegExp(r'/$'), '');
        try {
          await http.delete(
            Uri.parse(
              '$baseUrl/api/v1/me/push-installations/${Uri.encodeComponent(installationId)}',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 15));
        } catch (_) {
          // Logout must remain possible if push cleanup is unavailable.
        }
      }
    }
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _registeredInstallationId = null;
    if (FirebaseBootstrap.isConfiguredPlatform) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // The local Firebase session can still be signed out.
      }
    }
  }

  Future<void> _sendInstallation(String token) async {
    final bearer = await AuthService.getToken();
    if (bearer == null || bearer.isEmpty) return;
    final baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://blueviolet-viper-439935.hostingersite.com',
    ).replaceAll(RegExp(r'/$'), '');
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/me/push-installations'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $bearer',
          },
          body: jsonEncode({
            'installation_id': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _registeredInstallationId = _extractInstallationId(response.body) ?? token;
    }
  }

  String? _extractInstallationId(String body) {
    try {
      final decoded = jsonDecode(body);
      final root = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      final data = root?['data'] is Map
          ? Map<String, dynamic>.from(root!['data'] as Map)
          : root;
      final installation = data?['installation'] is Map
          ? Map<String, dynamic>.from(data!['installation'] as Map)
          : data;
      return installation?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'إتقان',
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'itqan_notifications',
          'إشعارات إتقان',
          channelDescription: 'إشعارات الدوائر والتحديثات',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
