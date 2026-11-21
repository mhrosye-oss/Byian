import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/home/home_screen.dart';
import 'package:itqan/features/home/widgets/itqan_bottom_nav_bar.dart';

void main() {
  testWidgets('home screen shows Bento content and persistent navigation',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    Finder navLabel(String label) => find.descendant(
      of: find.byType(ItqanBottomNavBar),
      matching: find.text(label),
    );

    await tester.dragUntilVisible(
      find.text('مساحتك اليومية'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    expect(find.text('مساحتك اليومية'), findsOneWidget);
    expect(navLabel('الرئيسية'), findsOneWidget);
    expect(navLabel('الصلاة'), findsOneWidget);
    expect(navLabel('التسبيح'), findsOneWidget);
    expect(navLabel('المزيد'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('ورد اليوم'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    expect(find.text('معلّم القرآن'), findsOneWidget);
    expect(find.text('ورد اليوم'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('جميع الخدمات الإسلامية'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    expect(find.text('جميع الخدمات الإسلامية'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    expect(find.text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا'), findsOneWidget);
    expect(navLabel('الرئيسية'), findsOneWidget);
    expect(navLabel('الصلاة'), findsOneWidget);
    expect(navLabel('التسبيح'), findsOneWidget);
    expect(navLabel('المزيد'), findsOneWidget);
  });
}
