import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/features/itqan_journey/application/itqan_journey_provider.dart';
import 'package:itqan/features/itqan_journey/share_journey/presentation/share_journey_screen.dart';

class _ShareJourneyRepository extends ItqanJourneyRepository {
  _ShareJourneyRepository()
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
      'data': {'xp_earned': 4},
    };
  }

  @override
  Future<Map<String, dynamic>> get(String endpoint) async {
    if (endpoint == 'gamification/tasks') {
      return {
        'tasks': [
          {
            'pillar': 'sharing',
            'title': 'مشاركة الخير',
            'description': 'شارك التطبيق مع الآخرين',
            'progress': 2,
            'target': 5,
            'status': 'in_progress',
            'xp_reward': 20,
            'coin_reward': 4,
          },
        ],
      };
    }
    return {};
  }

  @override
  Future<void> syncPendingActivities() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('does not record dismissal and records only after share success',
      (tester) async {
    final repository = _ShareJourneyRepository();
    final channel = const MethodChannel('dev.fluttercommunity.plus/share');
    var shareResult = '';
    channel.setMockMethodCallHandler((call) async => shareResult);
    addTearDown(() => channel.setMockMethodCallHandler(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itqanJourneyRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ShareJourneyScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 5'), findsOneWidget);

    await tester.tap(find.text('مشاركة رابط التطبيق'));
    await tester.pumpAndSettle();
    expect(repository.recordedActivities, 0);

    shareResult = 'com.android.contacts';
    await tester.tap(find.text('مشاركة رابط التطبيق'));
    await tester.pumpAndSettle();
    expect(repository.recordedActivities, 1);
    // Refreshing after a share re-reads the backend value; the client never
    // increments the task progress itself.
    expect(find.text('2 / 5'), findsOneWidget);
  });
}
