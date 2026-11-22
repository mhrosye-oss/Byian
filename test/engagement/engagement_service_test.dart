import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/features/engagement/data/services/engagement_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  String? currentToken;

  setUp(() {
    currentToken = 'secret-one';
    binding.defaultBinaryMessenger.setMockMethodCallHandler(storage,
        (call) async {
      if (call.method == 'read') return currentToken;
      return null;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(storage, null);
  });

  test('both placements and track-view use AuthService token per request',
      () async {
    final requests = <http.Request>[];
    final service = EngagementService(client: MockClient((request) async {
      requests.add(request);
      return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'data': [
              {
                'uuid': 'ad-1',
                'type': 'banner',
                'placement': 'home_top_desktop',
                'text': {'title': 'Title'},
                'media': {
                  'image': {'url': 'https://example.test/image.png'}
                },
                'action': {'type': 'open_url', 'url': 'https://example.test'},
              }
            ],
          }),
          200);
    }));

    final items = await service.fetchEngagementItems('home_top_desktop');
    expect(items.single.media.image, 'https://example.test/image.png');
    expect(items.single.action!.type, 'url');
    currentToken = 'secret-two';
    await service.fetchEngagementItems('welcome_popup');
    currentToken = 'secret-three';
    expect(await service.trackView('ad-1'), isTrue);
    expect(await service.trackView('ad-1'), isTrue);
    expect(requests.map((r) => r.url.path).toList(), [
      '/api/v1/engagement/home_top_desktop',
      '/api/v1/engagement/welcome_popup',
      '/api/v1/engagement/ad-1/track-view',
    ]);
    expect(requests.map((r) => r.method).toList(), ['GET', 'GET', 'POST']);
    expect(requests.map((r) => r.headers['Authorization']).toList(),
        ['Bearer secret-one', 'Bearer secret-two', 'Bearer secret-three']);
    expect(requests.last.headers['Content-Type'], 'application/json');
  });

  test('missing token is never substituted and failed tracking can retry',
      () async {
    currentToken = null;
    var posts = 0;
    final service = EngagementService(client: MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      if (request.method == 'POST') {
        posts++;
        return http.Response('private plain-text body', posts == 1 ? 500 : 204);
      }
      return http.Response('{"success":true,"count":0,"data":[]}', 200);
    }));
    await service.fetchEngagementItems('welcome_popup');
    expect(await service.trackView('item'), isFalse);
    expect(await service.trackView('item'), isTrue);
    expect(posts, 2);
  });

  test('concurrent tracking is sent once and shares its result', () async {
    final response = Completer<http.Response>();
    var posts = 0;
    final service = EngagementService(client: MockClient((request) {
      posts++;
      return response.future;
    }));
    final first = service.trackView('item');
    final second = service.trackView('item');
    await Future<void>.delayed(Duration.zero);
    expect(posts, 1);
    response.complete(http.Response('', 500));
    expect(await first, isFalse);
    expect(await second, isFalse);
  });

  test('debug status/body output never includes arbitrary sensitive body data',
      () async {
    final lines = <String>[];
    final oldPrint = debugPrint;
    debugPrint =
        (String? message, {int? wrapWidth}) => lines.add(message ?? '');
    addTearDown(() => debugPrint = oldPrint);
    final service = EngagementService(client: MockClient((request) async {
      return http.Response(
          jsonEncode({
            'success': false,
            'count': 0,
            'token': 'secret-one',
            'email': 'person@example.test',
            'message': 'Bearer secret-one',
            'data': [
              {'password': 'not-for-logs'}
            ],
          }),
          403);
    }));
    await service.fetchEngagementItems('welcome_popup');
    await service.trackView('item');
    final output = lines.join('\n');
    expect(output, contains('status 403'));
    expect(output, contains('body:'));
    expect(output, contains('[REDACTED]'));
    for (final sensitive in [
      'secret-one',
      'person@example.test',
      'not-for-logs',
      'Bearer',
      'Authorization'
    ]) {
      expect(output, isNot(contains(sensitive)));
    }
  });
}
