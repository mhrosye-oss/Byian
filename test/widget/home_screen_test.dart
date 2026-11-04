import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/home/home_screen.dart';

void main() {
  testWidgets('home screen shows Bento content and persistent navigation',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('أهلاً بك في إتقان'), findsOneWidget);
    expect(find.text('مصحفي'), findsOneWidget);
    expect(find.text('مساحتك اليومية'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('القرآن'), findsOneWidget);
    expect(find.text('الصلاة'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('خدمات إتقان'), findsOneWidget);
    expect(find.text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا'), findsOneWidget);
  });
}
