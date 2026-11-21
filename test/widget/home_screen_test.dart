import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/home/home_screen.dart';
import 'package:itqan/features/home/widgets/itqan_bottom_nav_bar.dart';

void main() {
  testWidgets('home screen loads scrollable content and persistent navigation',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverList), findsOneWidget);

    final navigation = find.byType(ItqanBottomNavBar);
    expect(navigation, findsOneWidget);
    for (final label in const ['الرئيسية', 'الصلاة', 'التسبيح', 'المزيد']) {
      expect(
        find.descendant(
          of: navigation,
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });
}
