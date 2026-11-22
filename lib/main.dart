import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/notification/notification_service.dart';
import 'core/services/fcm_service.dart';

Future<void> _initializeFirebaseMessaging() async {
  try {
    await Firebase.initializeApp();
    await FcmService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Firebase/FCM initialization failed: $error\n$stackTrace');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('reading_positions');
  await Hive.openBox('sessions');

  // Firebase Messaging must be ready before the login screen can register a
  // device or the app can handle an incoming message.
  await _initializeFirebaseMessaging();
  runApp(const ProviderScope(child: ItqanApp()));
  unawaited(NotificationService().init());
}
