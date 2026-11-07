import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/app.dart';
import 'package:itqan/features/mushaf/mushaf_screen.dart';
import 'package:itqan/features/quran/models/ayah.dart';
import 'package:itqan/features/surah_browser/surah_browser_screen.dart';
import 'package:itqan/l10n/app_localizations.dart' as generated_l10n;

void main() {
  testWidgets('generated screen strings load for Arabic and fallback locales', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: itqanLocalizationsDelegates,
        home: Builder(
          builder: (context) =>
              Text(generated_l10n.AppLocalizations.of(context)!.settingsTitle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('Quran browser builds with its generated Arabic labels',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahsProvider.overrideWith((ref) async => const <Surah>[])
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: itqanLocalizationsDelegates,
          home: const SurahBrowserScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('السور'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
