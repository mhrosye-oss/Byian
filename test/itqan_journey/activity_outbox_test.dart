import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/features/itqan_journey/application/itqan_journey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    hiveDirectory = await Directory.systemTemp.createTemp('itqan-outbox-');
    Hive.init(hiveDirectory.path);
    await AuthService.saveSession(
      name: 'Reader',
      email: 'reader@example.com',
      token: 'test-token',
    );
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('retries a queued activity with the same idempotency key', () async {
    final requestBodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      requestBodies.add(
        Map<String, dynamic>.from(jsonDecode(request.body) as Map),
      );
      if (requestBodies.length == 1) {
        return http.Response('{"message":"temporary failure"}', 503);
      }
      return http.Response(
        '{"success":true,"data":{"xp_earned":5}}',
        200,
      );
    });
    final repository = ItqanJourneyRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    await expectLater(
      repository.record('adhkar', metadata: {'count': 10}),
      throwsA(isA<ItqanJourneyException>()),
    );
    final outbox = await Hive.openBox('itqan_activity_outbox');
    expect(outbox.length, 1);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    await repository.syncPendingActivities();

    expect(requestBodies, hasLength(2));
    expect(requestBodies[1]['idempotency_key'],
        requestBodies[0]['idempotency_key']);
    expect(requestBodies[1]['metadata'], {'count': 10});
    expect(await Hive.openBox('itqan_activity_outbox'), isEmpty);
  });

  test('does not send a queued event for a different signed-in user', () async {
    final sentRequests = <http.Request>[];
    final client = MockClient((request) async {
      sentRequests.add(request);
      return http.Response('{"message":"temporary failure"}', 503);
    });
    final repository = ItqanJourneyRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    await expectLater(
      repository.record('dua'),
      throwsA(isA<ItqanJourneyException>()),
    );
    await AuthService.saveSession(
      name: 'Someone else',
      email: 'other@example.com',
      token: 'other-token',
    );

    await repository.syncPendingActivities();

    expect(sentRequests, hasLength(1));
    expect((await Hive.openBox('itqan_activity_outbox')).length, 1);
  });

  test('honors retry_after and retries a rate-limited activity with its UUID',
      () async {
    final requestBodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      requestBodies
          .add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      if (requestBodies.length == 1) {
        return http.Response(
          '{"code":"ACTIVITY_RATE_LIMIT","retry_after":120}',
          429,
        );
      }
      return http.Response(
        '{"success":true,"duplicate":true,"data":{"xp_earned":0,"coins_earned":0}}',
        200,
      );
    });
    final repository = ItqanJourneyRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    try {
      await repository.record('share', sourceType: 'share');
      fail('A rate-limited activity must remain pending.');
    } on ItqanJourneyException catch (error) {
      expect(error.queued, isTrue);
      expect(error.retryAfter, 120);
    }

    final outbox = await Hive.openBox('itqan_activity_outbox');
    expect(outbox.length, 1);
    final key = outbox.keys.single;
    final entry = Map<String, dynamic>.from(outbox.get(key) as Map);
    expect(entry['retry_after_at'], isNotNull);
    expect(requestBodies.single['source_type'], 'share');

    await repository.syncPendingActivities();
    expect(requestBodies, hasLength(1));

    entry['retry_after_at'] =
        DateTime.now().subtract(const Duration(seconds: 1)).toIso8601String();
    await outbox.put(key, entry);
    await repository.syncPendingActivities();

    expect(requestBodies, hasLength(2));
    expect(requestBodies.last['idempotency_key'],
        requestBodies.first['idempotency_key']);
    expect(outbox, isEmpty);
  });

  test('keeps a rejected 422 item for inspection without retrying it blindly',
      () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response(
        '{"message":"Validation failed","errors":{"activity_type":["invalid"]}}',
        422,
      );
    });
    final repository = ItqanJourneyRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    await expectLater(
      repository.record('unknown'),
      throwsA(
        isA<ItqanJourneyException>().having(
          (error) => error.validationErrors?['activity_type'],
          'validation errors',
          ['invalid'],
        ),
      ),
    );
    final outbox = await Hive.openBox('itqan_activity_outbox');
    expect(outbox.length, 1);
    expect((outbox.get(outbox.keys.single) as Map)['blocked_status'], 422);

    await repository.syncPendingActivities();
    expect(requestCount, 1);
    expect(outbox.length, 1);
  });
}
