import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/app.dart';
import 'package:itqan/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _secureStorage =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
const _splash = ValueKey('app-startup-splash');
const _error = ValueKey('app-startup-error');
const _ready = ValueKey('app-ready-screen');

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('secure storage retry can complete startup', (tester) async {
    final readKeys = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_secureStorage,
        (call) {
      expect(call.method, 'read');
      readKeys.add(call.arguments['key'] as String);
      if (readKeys.length == 1) throw PlatformException(code: 'unavailable');
      return Future<Object?>.value(null);
    });

    await tester.pumpWidget(const ItqanApp());
    await tester.pump();
    expect(find.byKey(_error), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    await tester.pump();
    expect(readKeys, ['auth_token', 'auth_token', 'itqan_bearer_token']);
    expect(find.byKey(_ready), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byKey(_error), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('secure storage failure shows an error and retry reads again',
      (tester) async {
    var reads = 0;
    final retryRead = Completer<String?>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_secureStorage,
        (call) {
      expect(call.method, 'read');
      expect(call.arguments['key'], 'auth_token');
      reads++;
      if (reads == 1) throw PlatformException(code: 'unavailable');
      return retryRead.future;
    });

    await tester.pumpWidget(const ItqanApp());
    await tester.pump();
    expect(reads, 1);
    expect(find.byKey(_error), findsOneWidget);
    expect(find.byKey(_ready), findsNothing);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(reads, 2);
    expect(find.byKey(_splash), findsOneWidget);
    expect(find.byKey(_ready), findsNothing);

    retryRead.completeError(PlatformException(code: 'still_unavailable'));
    await tester.pump();
    expect(find.byKey(_error), findsOneWidget);
    expect(find.byKey(_ready), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timed-out secure read cannot finish a later retry',
      (tester) async {
    final firstRead = Completer<String?>();
    final retryRead = Completer<String?>();
    var reads = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_secureStorage,
        (call) {
      expect(call.method, 'read');
      expect(call.arguments['key'], 'auth_token');
      reads++;
      return reads == 1 ? firstRead.future : retryRead.future;
    });

    await tester.pumpWidget(const ItqanApp());
    await tester.pump();
    expect(reads, 1);
    expect(find.byKey(_splash), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    expect(find.byKey(_splash), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(_error), findsOneWidget);
    expect(find.byKey(_ready), findsNothing);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(reads, 2);
    expect(find.byKey(_splash), findsOneWidget);
    firstRead.complete('stale-token');
    await tester.pump();
    expect(find.byKey(_splash), findsOneWidget);
    expect(find.byKey(_ready), findsNothing);

    retryRead.completeError(PlatformException(code: 'unavailable'));
    await tester.pump();
    expect(find.byKey(_error), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late secure storage failure after disposal is handled',
      (tester) async {
    final read = Completer<String?>();
    var reads = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_secureStorage,
        (call) {
      expect(call.method, 'read');
      expect(call.arguments['key'], 'auth_token');
      reads++;
      return read.future;
    });

    await tester.pumpWidget(const ItqanApp());
    await tester.pump();
    expect(reads, 1);
    expect(find.byKey(_splash), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    read.completeError(PlatformException(code: 'late_failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
