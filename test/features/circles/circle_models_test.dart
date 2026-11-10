import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/circles/application/circle_list_provider.dart';
import 'package:itqan/features/circles/data/circle_api_service.dart';
import 'package:itqan/features/circles/domain/circle_models.dart';
import 'package:itqan/features/circles/presentation/screens/create_circle_screen.dart';
import 'package:itqan/features/circles/presentation/screens/my_circles_screen.dart';
import 'package:itqan/features/circles/presentation/screens/whispers_sheet.dart';

void main() {
  group('Circle models', () {
    test('parses a circle with its type, role, and member count', () {
      final circle = Circle.fromJson({
        'id': 4,
        'uuid': 'circle-uuid',
        'name': 'حلقة القرآن',
        'members_count': 7,
        'my_role': 'owner',
        'type': {'id': 3, 'key': 'study_circle', 'name': 'حلقة علم'},
      });

      expect(circle.uuid, 'circle-uuid');
      expect(circle.type?.key, 'study_circle');
      expect(circle.membersCount, 7);
      expect(circle.myRole, 'owner');
    });
  });

  testWidgets(
      'create form offers server types and stays disabled until complete',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [circleApiServiceProvider.overrideWithValue(_FakeCircleApi())],
      child: const MaterialApp(home: CreateCircleScreen()),
    ));
    await tester.pumpAndSettle();

    final submit = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(submit.onPressed, isNull);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('العائلة'), findsWidgets);
    expect(find.text('حلقة علم'), findsOneWidget);

    await tester.tap(find.text('العائلة').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'عائلتي');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull);
  });

  testWidgets('my circles shows the direct entry action and role badge',
      (tester) async {
    final circle = Circle(
      id: 1,
      uuid: 'family-uuid',
      name: 'العائلة',
      type: const CircleType(id: 1, key: 'family', name: 'العائلة'),
      membersCount: 3,
      myRole: 'owner',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myCirclesProvider.overrideWith((ref) async => [circle]),
        circleApiServiceProvider.overrideWithValue(_FakeCircleApi()),
      ],
      child: const MaterialApp(home: MyCirclesScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('الدخول مباشرة'), findsOneWidget);
    expect(find.text('مالك'), findsOneWidget);
  });

  testWidgets('whispers sheet displays an empty state when the list is empty',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [circleApiServiceProvider.overrideWithValue(_FakeCircleApi())],
      child: MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () =>
                        CircleWhispersSheet.show(context, 'circle-uuid'),
                    child: const Text('فتح الهمسات'),
                  ),
                )),
      ),
    ));
    await tester.tap(find.text('فتح الهمسات'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد همسات بعد'), findsOneWidget);
  });
}

class _FakeCircleApi extends CircleApiService {
  @override
  Future<List<Map<String, dynamic>>> getTypes() async => [
        {'id': 1, 'key': 'family', 'name': 'العائلة'},
        {'id': 2, 'key': 'classroom', 'name': 'الفصل التعليمي'},
        {'id': 3, 'key': 'study_circle', 'name': 'حلقة علم'},
        {'id': 4, 'key': 'goodness', 'name': 'مجموعة خير'},
        {'id': 5, 'key': 'companions', 'name': 'دائرة الرفقة'},
      ];

  @override
  Future<List<Map<String, dynamic>>> getWhispers(String uuid) async => [];
}
