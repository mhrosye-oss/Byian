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

    await repository.syncPendingActivities();

    expect(requestBodies, hasLength(2));
    expect(
      requestBodies[1]['idempotency_key'],
      requestBodies[0]['idempotency_key'],
    );
    expect(requestBodies[1]['metadata'], {'count': 10});
    expect(outbox, isEmpty);
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
}
