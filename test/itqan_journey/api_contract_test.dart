import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/features/gamification/data/api/gamification_api.dart';
import 'package:itqan/features/itqan_journey/application/itqan_journey_provider.dart';
import 'package:itqan/features/itqan_journey/data/journey_auth_api.dart';

/// Deterministic contract mock: no production or staging host is contacted.
void main() {
  test('authentication contract maps validation errors without fake success',
      () async {
    late http.Request request;
    final api = JourneyAuthApi(
      client: MockClient((received) async {
        request = received;
        return http.Response(
            jsonEncode({'message': 'بيانات الدخول غير صحيحة'}), 422,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
      baseUrl: 'http://mock-itqan.test',
    );

    await expectLater(
        api.login('user@example.test', 'wrong-password'),
        throwsA(isA<JourneyAuthException>()
            .having((e) => e.status, 'status', 422)));
    expect(request.url.toString(), 'http://mock-itqan.test/api/v1/auth/login');
    expect(jsonDecode(request.body), {
      'email': 'user@example.test',
      'password': 'wrong-password',
    });
  });

  test('gamification API sends bearer auth and preserves endpoint paths',
      () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
          jsonEncode({
            'data': {'ok': true}
          }),
          200);
    });
    final api = GamificationApi(
      client: client,
      baseUrl: 'http://mock-itqan.test',
      tokenProvider: () async => 'mock-token',
    );

    await api.get('gamification/profile');
    await api.post('gamification/activities', {
      'activity_type': 'adhkar',
      'idempotency_key': 'fixed-key',
    });

    expect(requests.map((request) => request.url.toString()), [
      'http://mock-itqan.test/api/v1/gamification/profile',
      'http://mock-itqan.test/api/v1/gamification/activities',
    ]);
    expect(
        requests.every((request) =>
            request.headers['authorization'] == 'Bearer mock-token'),
        true);
    expect(jsonDecode(requests.last.body), {
      'activity_type': 'adhkar',
      'idempotency_key': 'fixed-key',
    });
  });

  test(
      'journey repository sends a UUID idempotency key and returns server data',
      () async {
    late http.Request request;
    final repository = ItqanJourneyRepository(
      client: MockClient((received) async {
        request = received;
        return http.Response(
            jsonEncode({
              'success': true,
              'duplicate': false,
              'data': {'activity_id': 12, 'xp_earned': 5},
            }),
            200);
      }),
      baseUrl: 'http://mock-itqan.test',
      tokenProvider: () async => 'mock-token',
    );

    final response =
        await repository.record('quran.reading', metadata: {'pages': 2});
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final key = body['idempotency_key'] as String;

    expect(request.url.path, '/api/v1/gamification/activities');
    expect(request.headers['authorization'], 'Bearer mock-token');
    expect(body['activity_type'], 'quran.reading');
    expect(body['metadata'], {'pages': 2});
    expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(key), true);
    expect(response['data'], {'activity_id': 12, 'xp_earned': 5});
  });

  test(
      'rate limit contract exposes status and retry_after without fabricating success',
      () async {
    final api = GamificationApi(
      client: MockClient((_) async => http.Response(
          jsonEncode({
            'error': {
              'message': 'حاول لاحقاً',
              'code': 'rate_limited',
              'retry_after': 30
            },
          }),
          429,
          headers: {'content-type': 'application/json; charset=utf-8'})),
      baseUrl: 'http://mock-itqan.test',
      tokenProvider: () async => 'mock-token',
    );

    await expectLater(
      api.get('gamification/tasks'),
      throwsA(isA<GamificationApiException>()
          .having((e) => e.statusCode, 'status', 429)
          .having((e) => e.retryAfter, 'retry_after', 30)),
    );
  });
}
