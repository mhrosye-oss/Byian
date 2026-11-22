import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/l10n/app_localizations.dart';
import 'package:itqan/features/home/home_screen.dart';

void main() {
  testWidgets('home screen shows Bento content and persistent navigation',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الصلاة'), findsOneWidget);
    expect(find.text('التسبيح'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);

    final scrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text('مساحتك اليومية'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('مساحتك اليومية'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('معلّم القرآن'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('معلّم القرآن'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('جميع الخدمات الإسلامية'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('جميع الخدمات الإسلامية'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا'), findsOneWidget);
  });
}
