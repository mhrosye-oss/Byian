import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/circles/presentation/circles_entry_screen.dart';

class ItqanApp extends StatefulWidget {
  const ItqanApp({super.key});

  @override
  State<ItqanApp> createState() => _ItqanAppState();
}

class _ItqanAppState extends State<ItqanApp> {
  final AppSettingsProvider _settings = AppSettingsProvider();
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CirclesEntryScreen(),
      ),
      GoRoute(
        path: '/itqan-home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.load();
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
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
        return AppSettingsScope(
          settings: _settings,
          child: MaterialApp.router(
          title: 'Itqan',
          debugShowCheckedModeBanner: false,
          // The current screens use the light-only brand palette. Do not let
          // a stale persisted dark-mode flag turn them into a grey/dark view.
          themeMode: ThemeMode.light,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
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
          routerConfig: _router,
          ),
        );
      },
    );
  }
}
