import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/l10n/app_localizations.dart';
import 'package:itqan/core/theme/app_theme.dart';
import 'package:itqan/core/ui/base_widgets.dart';
import 'package:itqan/features/scoring/models/score_result.dart';
import 'package:itqan/features/scoring/widgets/word_detail_sheet.dart';

void main() {
  Widget testApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('service banner renders its title and supporting details',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(testApp(
      TeacherServiceCard(
        title: 'معلّم القرآن',
        description: 'تدرّب على التلاوة يوميًا',
        icon: Icons.menu_book,
        onTap: () => tapped = true,
        badgeText: 'جديد',
      ),
    ));

    expect(find.text('معلّم القرآن'), findsOneWidget);
    expect(find.text('تدرّب على التلاوة يوميًا'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);

    await tester.tap(find.text('معلّم القرآن'));
    expect(tapped, isTrue);
  });

  testWidgets('word detail bottom sheet opens and is visible', (tester) async {
    await tester.pumpWidget(testApp(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showWordDetail(
            context,
            const WordScore(word: 'بِسْمِ', score: 0.9),
          ),
          child: const Text('افتح التفاصيل'),
        ),
      ),
    ));

    await tester.tap(find.text('افتح التفاصيل'));
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('إغلاق'), findsOneWidget);
  });
}
