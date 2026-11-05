import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/settings/app_settings_provider.dart';
import 'features/home/home_screen.dart';

class ItqanApp extends StatelessWidget {
  const ItqanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer للاستماع لتغيير اللغة والوضع الليلي بأمان
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Itqan',
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1B5E20),
            scaffoldBackgroundColor: const Color(0xFFF9F6F0),
            cardColor: Colors.white,
            dividerColor: Colors.grey.shade300,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20), brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1B5E20),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.grey.shade800,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20), brightness: Brightness.dark),
            useMaterial3: true,
          ),
          locale: settings.locale,
          supportedLocales: const [
            Locale('ar'), Locale('en'), Locale('fr'), Locale('es'), Locale('ur'), 
            Locale('id'), Locale('hi'), Locale('bn'), Locale('fa'), Locale('uz')
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        );
      },
    );
  }
}
