import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/core/services/fcm_service.dart';

void main() {
  group('FcmService topic helpers', () {
    test('exposes the independent announcements topic name', () {
      expect(FcmService.announcementsTopic, 'itqan_announcements');
    });

    test(
      'rejects the /topics/ prefix used by the legacy endpoint format',
      () async {
        await expectLater(
          FcmService.subscribeToTopic('/topics/itqan_announcements'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('rejects an empty topic name', () async {
      await expectLater(
        FcmService.unsubscribeFromTopic('  '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
