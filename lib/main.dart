import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/notification/notification_service.dart';
import 'features/adhan/services/adhan_audio_handler.dart';
import 'features/adhan/services/adhan_scheduler.dart';

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

  // --- تهيئة خدمة الأذان (قبل runApp إلزاميًا) ---
  final adhanHandler = await AudioService.init(
    builder: () => AdhanAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.itqan.itqan.adhan.channel',
      androidNotificationChannelName: 'الأذان الصوتي',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_itqan_launcher',
      androidStopForegroundOnPause: true,
    ),
  );
  // init محمي بحارس _initialized داخليًا: عند Full Restart (R)
  // لا تُهيَّأ AdhanScheduler مرتين فلا يحدث PlatformException مزدوج.
  AdhanScheduler.instance.init(adhanHandler);
  // ----------------------------------------------

  runApp(const ProviderScope(child: ItqanApp()));
}
