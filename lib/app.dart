import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_localizations.dart';
import 'core/settings/app_settings_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class ItqanApp extends StatefulWidget {
  const ItqanApp({super.key});

  @override
  State<ItqanApp> createState() => _ItqanAppState();
}

class _ItqanAppState extends State<ItqanApp> {
  final AppSettingsProvider _settings = AppSettingsProvider();
  bool _isLoaded = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.load();
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isLoaded = true;
        _showOnboarding =
            !(preferences.getBool('onboarding_completed') ?? false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // شاشة البداية (Splash Screen) لمنع الانهيار
    if (!_isLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF1B5E20),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_rounded, size: 72, color: Colors.white),
                SizedBox(height: 18),
                Text(
                  'إتقان',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 22),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, child) {
        return MaterialApp(
          title: 'Itqan',
          debugShowCheckedModeBanner: false,
          themeMode: _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
          locale: _settings.locale,
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
          home: _showOnboarding ? const OnboardingScreen() : const HomeScreen(),
        );
      },
    );
  }
}
