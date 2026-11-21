import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService initialization error: $e');
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('reading_positions');
  await Hive.openBox('sessions');

  try {
    await FcmService.initialize();
  } catch (error) {
    debugPrint('FCM initialization failed: $error');
  }

  runApp(const ProviderScope(child: ItqanApp()));
}
