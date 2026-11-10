import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/features/itqan_journey/application/itqan_journey_provider.dart';
import 'package:itqan/features/itqan_journey/adhkar_journey/presentation/adhkar_journey_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingJourneyRepository extends ItqanJourneyRepository {
  _RecordingJourneyRepository()
      : super(
          client: MockClient((_) async => http.Response('{}', 200)),
          baseUrl: 'https://example.test',
        );

  int recordedActivities = 0;

  @override
  Future<Map<String, dynamic>> record(
    String type, {
    Map<String, dynamic>? metadata,
    String? sourceType,
    int? sourceId,
  }) async {
    recordedActivities++;
    return {
      'success': true,
      'duplicate': false,
      'data': {'xp_earned': 5},
    };
  }

  @override
  Future<Map<String, dynamic>> get(String endpoint) async => {};

  @override
  Future<void> syncPendingActivities() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records the dhikr once only when its target is reached',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _RecordingJourneyRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itqanJourneyRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdhkarJourneyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final dhikr = find.textContaining('بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ');
    await tester.ensureVisible(dhikr);
    await tester.pumpAndSettle();
    final card = find.ancestor(of: dhikr, matching: find.byType(Card)).first;
    final counter =
        find.descendant(of: card, matching: find.byType(FilledButton));

    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(repository.recordedActivities, 0);
    expect(find.text('الهدف: 1 / 3'), findsOneWidget);

    await tester.tap(counter);
    await tester.pumpAndSettle();
    await tester.tap(counter);
    await tester.pumpAndSettle();
    expect(repository.recordedActivities, 1);
    expect(find.text('مكتمل'), findsOneWidget);

    final saved = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final progress =
        jsonDecode(saved.getString('journey_adhkar_${date}_morning_evening')!)
            as Map;
    expect((progress['completed'] as List).contains(1), isTrue);
  });
}
