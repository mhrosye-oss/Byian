import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/itqan_journey/dua_journey/presentation/dua_journey_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('filters by category and retains favorites globally',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    Future<void> showScreen() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DuaJourneyScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await showScreen();
    expect(find.textContaining('دعاء للوالدين'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أدعية نبوية').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('دعاء الهم والحزن'), findsOneWidget);
    expect(find.textContaining('دعاء للوالدين'), findsNothing);

    // Return to all categories and favorite a Quranic dua.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كل التصنيفات').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إضافة إلى المفضلة').first);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('journey_duas_favorites'),
        contains('دعاء للوالدين'));

    await tester.pumpWidget(const SizedBox.shrink());
    await showScreen();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
