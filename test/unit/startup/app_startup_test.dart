import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/core/startup/app_startup.dart';

void main() {
  group('AppStartup', () {
    test('opens local boxes in order and reuses successful initialization',
        () async {
      final calls = <String>[];
      final startup = AppStartup(
        orientationSetup: () async { calls.add('orientation'); },
        storageSetup: () async { calls.add('storage'); },
        boxOpener: (name) async { calls.add(name); },
        isBoxOpen: (_) => false,
      );

      await Future.wait([startup.initialize(), startup.initialize()]);
      await startup.initialize();

      expect(calls, [
        'orientation',
        'storage',
        'settings',
        'reading_positions',
        'sessions',
      ]);
    });

    test('retries failed box opening without reinitializing Hive', () async {
      final openBoxes = <String>{};
      var storageSetupCount = 0;
      var failReadingPositionsOnce = true;
      final startup = AppStartup(
        orientationSetup: () async {},
        storageSetup: () async { storageSetupCount++; },
        boxOpener: (name) async {
          if (name == 'reading_positions' && failReadingPositionsOnce) {
            failReadingPositionsOnce = false;
            throw StateError('temporary storage error');
          }
          openBoxes.add(name);
        },
        isBoxOpen: openBoxes.contains,
      );

      await expectLater(startup.initialize(), throwsStateError);
      await startup.initialize();

      expect(storageSetupCount, 1);
      expect(
        openBoxes,
        containsAll(['settings', 'reading_positions', 'sessions']),
      );
    });
  });
}
