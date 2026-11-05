import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/settings/app_settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت اتجاه الشاشة عمودياً
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // تهيئة الإعدادات قبل تشغيل التطبيق
  final settings = AppSettingsProvider();
  await settings.load();

  runApp(
    ProviderScope(
      child: ChangeNotifierProvider<AppSettingsProvider>.value(
        value: settings,
        child: const ItqanApp(),
      ),
    ),
  );
}
