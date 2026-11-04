import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/l10n/app_localizations.dart';

import 'core/settings/app_settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Itqan: Dart entrypoint reached; drawing startup UI.');
  runApp(const ItqanBootstrap());
}

class ItqanBootstrap extends StatefulWidget {
  const ItqanBootstrap({super.key});

  @override
  State<ItqanBootstrap> createState() => _ItqanBootstrapState();
}

class _ItqanBootstrapState extends State<ItqanBootstrap> {
  bool _ready = false;
  bool _slow = false;
  bool _hiveInitialized = false;
  bool _running = false;
  bool _showOnboarding = true;
  String? _error;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    if (_running || _ready) return;
    _running = true;
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (mounted && !_ready && _error == null) setState(() => _slow = true);
    });
    if (mounted) setState(() { _slow = false; _error = null; });
    try {
      if (!_hiveInitialized) {
        await Hive.initFlutter();
        _hiveInitialized = true;
      }
      await _openBox('settings');
      await _openBox('sessions');
      await _openBox('reading_positions');
      final done = Hive.box('settings').get('onboarding_done', defaultValue: false) == true;
      if (!mounted) return;
      setState(() {
        _showOnboarding = !done;
        _ready = true;
        _slow = false;
        _error = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Itqan startup initialization failed: $error\n$stackTrace');
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _running = false;
      _watchdog?.cancel();
      if (mounted && _error != null) setState(() {});
    }
  }

  Future<void> _openBox(String name) async {
    if (!Hive.isBoxOpen(name)) await Hive.openBox(name);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return ProviderScope(
        child: ItqanAppWithOnboarding(showOnboarding: _showOnboarding),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: ItqanColors.cream,
        colorScheme: ColorScheme.fromSeed(seedColor: ItqanColors.emerald),
      ),
      home: _StartupScreen(slow: _slow, error: _error, onRetry: _running ? null : _initialize),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({required this.slow, required this.error, required this.onRetry});
  final bool slow;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.void_,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded, color: ItqanColors.gold, size: 54),
                const SizedBox(height: 14),
                const Text('إتقان', textDirection: TextDirection.rtl,
                    style: TextStyle(color: ItqanColors.gold, fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(height: 22),
                if (error == null) ...[
                  const CircularProgressIndicator(color: ItqanColors.gold),
                  const SizedBox(height: 16),
                  Text(slow ? 'ما زال التطبيق يجهز بياناته. يرجى الانتظار قليلًا.' : 'جارٍ تجهيز التطبيق…',
                      textDirection: TextDirection.rtl, textAlign: TextAlign.center,
                      style: const TextStyle(color: ItqanColors.silver)),
                ] else ...[
                  const Text('تعذر تجهيز بيانات التطبيق.', textDirection: TextDirection.rtl,
                      style: TextStyle(color: ItqanColors.snow)),
                  const SizedBox(height: 8),
                  Text(error!, textDirection: TextDirection.ltr, textAlign: TextAlign.center,
                      style: const TextStyle(color: ItqanColors.mist, fontSize: 11)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
                ],
              ]),
            ),
          ),
        ),
      );
}

class ItqanAppWithOnboarding extends StatefulWidget {
  const ItqanAppWithOnboarding({super.key, required this.showOnboarding});
  final bool showOnboarding;

  @override
  State<ItqanAppWithOnboarding> createState() => _ItqanAppWithOnboardingState();
}

class _ItqanAppWithOnboardingState extends State<ItqanAppWithOnboarding> {
  late final AppSettingsProvider _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettingsProvider();
    unawaited(_settings.load());
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSettingsScope(
        settings: _settings,
        child: AnimatedBuilder(
          animation: _settings,
          builder: (context, _) {
            final dark = _settings.isDarkMode;
            return MaterialApp(
              title: 'Itqan',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
                scaffoldBackgroundColor: const Color(0xFF121A15),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1B5E20),
                  brightness: Brightness.dark,
                  surface: const Color(0xFF1D2720),
                ),
              ),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              locale: _settings.locale,
              supportedLocales: const [
        Locale('ar'), Locale('en'), Locale('fr'), Locale('ur'), Locale('id'),
        Locale('tr'), Locale('es'), Locale('de'), Locale('ru'), Locale('zh'),
        Locale('ja'), Locale('ko'), Locale('hi'), Locale('bn'), Locale('fa'),
        Locale('ms'), Locale('sw'), Locale('pt'), Locale('it'), Locale('nl'),
        Locale('pl'), Locale('uk'), Locale('ro'), Locale('el'), Locale('cs'),
        Locale('sv'), Locale('he'), Locale('th'), Locale('vi'), Locale('az')
      ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => Directionality(
                textDirection: const {'ar', 'ur'}.contains(Localizations.localeOf(context).languageCode)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
              home: widget.showOnboarding ? const OnboardingScreen() : const HomeScreen(),
            );
          },
        ),
      );
}
