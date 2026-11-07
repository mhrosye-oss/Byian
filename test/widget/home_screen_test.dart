import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:itqan/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('home screen shows Bento content and persistent navigation',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    expect(find.text('أهلاً بك في إتقان'), findsOneWidget);
    expect(find.text('مصحفي'), findsOneWidget);
    expect(find.text('مساحتك اليومية'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('القرآن'), findsOneWidget);
    expect(find.text('الصلاة'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('خدمات إتقان'), findsOneWidget);
    expect(find.text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا'), findsOneWidget);
  });
}
