import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/main.dart';

Future<void> _succeed() async {}

Widget _gate({
  required Future<void> Function() storage,
  Future<void> Function() orientation = _succeed,
  Future<void> Function() notifications = _succeed,
}) {
  return StartupGate(
    initializeStorage: storage,
    configureOrientation: orientation,
    initializeNotifications: notifications,
    child: const MaterialApp(home: Scaffold(body: Text('App ready'))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first frame is visible while storage is pending', (tester) async {
    final storage = Completer<void>();
    final orientation = Completer<void>();
    SchedulerPhase? phaseWhenStorageStarted;
    var notificationCalls = 0;

    await tester.pumpWidget(_gate(
      storage: () {
        phaseWhenStorageStarted = SchedulerBinding.instance.schedulerPhase;
        return storage.future;
      },
      orientation: () => orientation.future,
      notifications: () async {
        notificationCalls++;
      },
    ));

    expect(phaseWhenStorageStarted, SchedulerPhase.postFrameCallbacks);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('App ready'), findsNothing);
    expect(notificationCalls, 1);

    storage.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    orientation.complete();
  });

  testWidgets('slow storage shows guidance and completes without a retry',
      (tester) async {
    final storage = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(_gate(storage: () {
      calls++;
      return storage.future;
    }));
    await tester.pump(const Duration(seconds: 16));
    expect(find.textContaining('وقتًا أطول من المتوقع'), findsOneWidget);
    expect(calls, 1);

    storage.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('storage failure is shown and retry waits for storage',
      (tester) async {
    var calls = 0;
    final retry = Completer<void>();
    await tester.pumpWidget(_gate(storage: () {
      calls++;
      if (calls == 1) return Future<void>.error(StateError('storage failed'));
      return retry.future;
    }));
    await tester.pump();
    expect(find.textContaining('تعذّر تجهيز بيانات التطبيق'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    retry.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orientation and notification failures do not block the app',
      (tester) async {
    var orientationCalls = 0;
    var notificationCalls = 0;
    await tester.pumpWidget(_gate(
      storage: _succeed,
      orientation: () async {
        orientationCalls++;
        throw StateError('orientation failed');
      },
      notifications: () async {
        notificationCalls++;
        throw StateError('notifications failed');
      },
    ));
    await tester.pump();
    await tester.pump();

    expect(orientationCalls, 1);
    expect(notificationCalls, 1);
    expect(find.text('App ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late storage failure after disposal is handled', (tester) async {
    final storage = Completer<void>();
    await tester.pumpWidget(_gate(storage: () => storage.future));
    await tester.pumpWidget(const SizedBox.shrink());
    storage.completeError(StateError('late storage failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('storage initialization opens all boxes and preserves existing data',
      () async {
    final dir = await Directory.systemTemp.createTemp('itqan_startup_test_');
    addTearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });
    Future<void> initializeHiveForTest() async => Hive.init(dir.path);

    await initializeHiveForTest();
    final settings = await Hive.openBox<dynamic>('settings');
    await settings.put('existing', 'preserved');

    await initializeAppStorage(initializeHive: initializeHiveForTest);
    expect(Hive.isBoxOpen('settings'), isTrue);
    expect(Hive.isBoxOpen('reading_positions'), isTrue);
    expect(Hive.isBoxOpen('sessions'), isTrue);
    expect(Hive.box('settings').get('existing'), 'preserved');

    await Hive.close();
    await initializeAppStorage(initializeHive: initializeHiveForTest);
    expect(Hive.box('settings').get('existing'), 'preserved');
    expect(Hive.isBoxOpen('reading_positions'), isTrue);
    expect(Hive.isBoxOpen('sessions'), isTrue);
  });
}
