import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_service.dart';

// Locale provider — driven by user settings
final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.language) {
    case 'arabic':
      return const Locale('ar');
    case 'english':
      return const Locale('en');
    case 'french':
      return const Locale('fr');
    default:
      return const Locale('ar'); // Arabic is DEFAULT
  }
});

class ItqanApp extends ConsumerWidget {
  const ItqanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'إتقان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
      themeMode: AppSettingsScope.of(context).isDarkMode ? ThemeMode.dark : ThemeMode.light,,

      // Localization
      locale: locale,
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

      // RTL for Arabic, LTR for others
      builder: (context, child) {
        final isArabic = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },

      home: const HomeScreen(),
    );
  }
}
