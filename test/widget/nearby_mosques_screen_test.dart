import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
// Test the already-pinned Android implementation without changing pubspec.
// ignore: depend_on_referenced_packages
import 'package:geolocator_android/geolocator_android.dart' show GeolocatorAndroid;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/features/nearby_mosques/presentation/nearby_mosques_screen.dart';

class FakeLocation extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission permissionResult = LocationPermission.whileInUse;
  Future<bool> Function()? serviceCheck;
  Future<LocationPermission> Function()? permissionCheck;
  Future<LocationPermission> Function()? permissionRequest;
  Future<Position> Function()? positionRequest;
  bool settingsOpenResult = true;
  int serviceChecks = 0;
  int permissionChecks = 0;
  int permissionRequests = 0;
  int positionRequests = 0;
  int appSettingsOpens = 0;
  int locationSettingsOpens = 0;
  LocationSettings? lastSettings;

  static final position = Position(
    latitude: 21.4225,
    longitude: 39.8262,
    timestamp: DateTime.utc(2026),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<bool> isLocationServiceEnabled() {
    serviceChecks++;
    return serviceCheck?.call() ?? Future.value(serviceEnabled);
  }

  @override
  Future<LocationPermission> checkPermission() {
    permissionChecks++;
    return permissionCheck?.call() ?? Future.value(permission);
  }

  @override
  Future<LocationPermission> requestPermission() {
    permissionRequests++;
    return permissionRequest?.call() ?? Future.value(permissionResult);
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    positionRequests++;
    lastSettings = locationSettings;
    return positionRequest?.call() ?? Future.value(position);
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpens++;
    return settingsOpenResult;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpens++;
    return settingsOpenResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GeolocatorPlatform originalLocation;
  late FakeLocation location;
  late MockClient client;
  late List<http.Request> requests;

  setUp(() {
    originalLocation = GeolocatorPlatform.instance;
    location = FakeLocation();
    GeolocatorPlatform.instance = location;
    requests = [];
    client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 1,
              'lat': 21.423,
              'lon': 39.826,
              'tags': {'name': 'مسجد الاختبار'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalLocation;
    client.close();
  });

  Future<void> showScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NearbyMosquesScreen(httpClient: client),
    ));
    await tester.pump();
  }

  Future<void> retry(WidgetTester tester) async {
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
  }

  Future<void> expectSuccess(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(find.text('مسجد الاختبار'), findsOneWidget);
    expect(find.text('موقعك الجغرافي نشط'), findsOneWidget);
    expect(find.textContaining('انتهت مهلة تحديد الموقع'), findsNothing);
    expect(requests, hasLength(1));
    expect(requests.single.bodyFields['data'], contains('21.4225,39.8262'));
    expect(location.lastSettings?.accuracy, LocationAccuracy.medium);
    final timeLimit = location.lastSettings!.timeLimit!;
    expect(timeLimit, greaterThan(Duration.zero));
    expect(timeLimit, lessThanOrEqualTo(const Duration(seconds: 15)));
  }

  testWidgets('disabled services show settings and retry succeeds offline',
      (tester) async {
    location.serviceEnabled = false;
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('خدمة تحديد الموقع معطّلة'), findsOneWidget);
    expect(find.text('فتح إعدادات الموقع'), findsOneWidget);
    expect(location.permissionChecks, 0);
    expect(requests, isEmpty);

    await tester.tap(find.text('فتح إعدادات الموقع'));
    await tester.pump();
    expect(location.locationSettingsOpens, 1);
    expect(location.appSettingsOpens, 0);
    location.serviceEnabled = true;
    await retry(tester);
    await expectSuccess(tester);
  });

  testWidgets('denied permission can be requested again explicitly',
      (tester) async {
    location.permission = LocationPermission.denied;
    location.permissionResult = LocationPermission.denied;
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('تم رفض إذن الموقع'), findsOneWidget);
    expect(find.text('فتح إعدادات التطبيق'), findsNothing);
    expect(location.permissionRequests, 1);
    expect(location.positionRequests, 0);
    expect(requests, isEmpty);

    location.permissionResult = LocationPermission.whileInUse;
    await retry(tester);
    await expectSuccess(tester);
    expect(location.permissionRequests, 2);
  });

  testWidgets('permanent denial opens app settings and retry rechecks permission',
      (tester) async {
    location.permission = LocationPermission.denied;
    location.permissionResult = LocationPermission.deniedForever;
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('رُفض إذن الموقع بشكل دائم'), findsOneWidget);
    expect(find.text('فتح إعدادات التطبيق'), findsOneWidget);
    expect(location.permissionRequests, 1);
    expect(location.positionRequests, 0);

    await tester.tap(find.text('فتح إعدادات التطبيق'));
    await tester.pump();
    expect(location.appSettingsOpens, 1);
    expect(location.locationSettingsOpens, 0);
    location.permission = LocationPermission.whileInUse;
    await retry(tester);
    await expectSuccess(tester);
    expect(location.permissionRequests, 1);
  });

  testWidgets('already permanently denied does not prompt again', (tester) async {
    location.permission = LocationPermission.deniedForever;
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('رُفض إذن الموقع بشكل دائم'), findsOneWidget);
    await retry(tester);
    await tester.pumpAndSettle();
    expect(location.permissionRequests, 0);
    expect(location.positionRequests, 0);
  });

  testWidgets('settings failure explains the manual alternative', (tester) async {
    location.serviceEnabled = false;
    location.settingsOpenResult = false;
    await showScreen(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('فتح إعدادات الموقع'));
    await tester.pump();
    expect(find.textContaining('شغّل الموقع يدويًا'), findsOneWidget);
  });

  for (final stage in ['service', 'permission check', 'position']) {
    testWidgets('$stage timeout ignores late result and allows retry',
        (tester) async {
      final service = Completer<bool>();
      final permission = Completer<LocationPermission>();
      final position = Completer<Position>();
      if (stage == 'service') location.serviceCheck = () => service.future;
      if (stage == 'permission check') {
        location.permissionCheck = () => permission.future;
      }
      if (stage == 'position') location.positionRequest = () => position.future;

      await showScreen(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(find.textContaining('انتهت مهلة تحديد الموقع'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(requests, isEmpty);

      // A response arriving after the deadline must not advance the old flow.
      if (stage == 'service') service.complete(true);
      if (stage == 'permission check') {
        permission.complete(LocationPermission.whileInUse);
      }
      if (stage == 'position') position.complete(FakeLocation.position);
      await tester.pump();
      expect(requests, isEmpty);
      if (stage == 'service') expect(location.permissionChecks, 0);
      if (stage == 'permission check') expect(location.positionRequests, 0);

      location.serviceCheck = null;
      location.permissionCheck = null;
      location.positionRequest = null;
      await retry(tester);
      await expectSuccess(tester);
    });
  }

  testWidgets('permission dialog timeout reuses in-flight request on retry',
      (tester) async {
    final permission = Completer<LocationPermission>();
    location.permission = LocationPermission.denied;
    location.permissionRequest = () => permission.future;
    await showScreen(tester);
    expect(location.permissionRequests, 1);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(find.textContaining('انتهت مهلة تحديد الموقع'), findsOneWidget);
    expect(location.positionRequests, 0);

    await retry(tester);
    expect(location.permissionRequests, 1);
    permission.complete(LocationPermission.whileInUse);
    await expectSuccess(tester);
    expect(location.permissionRequests, 1);
    expect(location.positionRequests, 1);
  });

  testWidgets('pending permission request is reused after reopening the screen',
      (tester) async {
    final permission = Completer<LocationPermission>();
    location.permission = LocationPermission.denied;
    location.permissionRequest = () => permission.future;
    await showScreen(tester);
    expect(location.permissionRequests, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await showScreen(tester);
    expect(location.permissionRequests, 1);
    permission.complete(LocationPermission.whileInUse);
    await expectSuccess(tester);
    expect(location.positionRequests, 1);
  });

  testWidgets('late position cannot overwrite a successful retry', (tester) async {
    final oldPosition = Completer<Position>();
    location.positionRequest = () => oldPosition.future;
    await showScreen(tester);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    location.positionRequest = null;
    await retry(tester);
    await expectSuccess(tester);
    oldPosition.completeError(StateError('late platform error'));
    await tester.pump();
    expect(find.text('مسجد الاختبار'), findsOneWidget);
    expect(requests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android channel receives native cancellation on timeout',
      (tester) async {
    GeolocatorPlatform.instance = GeolocatorAndroid();
    const channel = MethodChannel('flutter.baseflow.com/geolocator_android');
    final pending = Completer<Object?>();
    final calls = <MethodCall>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 2; // whileInUse
        case 'getCurrentPosition':
          return pending.future;
        case 'cancelGetCurrentPosition':
          return null;
        default:
          throw MissingPluginException(call.method);
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await showScreen(tester);
    expect(calls.where((call) => call.method == 'getCurrentPosition'), hasLength(1));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(find.textContaining('انتهت مهلة تحديد الموقع'), findsOneWidget);
    final getCall = calls.singleWhere((call) => call.method == 'getCurrentPosition');
    final cancelCall = calls.singleWhere((call) => call.method == 'cancelGetCurrentPosition');
    expect(cancelCall.arguments['requestId'], getCall.arguments['requestId']);
    expect(requests, isEmpty);
    pending.complete(<String, Object?>{});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('one deadline covers all location stages together', (tester) async {
    final service = Completer<bool>();
    final permission = Completer<LocationPermission>();
    location.serviceCheck = () => service.future;
    location.permissionCheck = () => permission.future;
    await showScreen(tester);
    await tester.pump(const Duration(seconds: 8));
    service.complete(true);
    await tester.pump();
    expect(location.permissionChecks, 1);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(find.textContaining('انتهت مهلة تحديد الموقع'), findsOneWidget);
    permission.complete(LocationPermission.whileInUse);
    await tester.pump();
    expect(location.positionRequests, 0);
    expect(requests, isEmpty);
  });

  testWidgets('leaving the screen stops late steps from requesting permission',
      (tester) async {
    final permission = Completer<LocationPermission>();
    location.permissionCheck = () => permission.future;
    await showScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    permission.complete(LocationPermission.denied);
    await tester.pump();
    expect(location.permissionRequests, 0);
    expect(location.positionRequests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service disabled during location fix uses disabled message',
      (tester) async {
    location.positionRequest = () =>
        Future.error(const LocationServiceDisabledException());
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('خدمة تحديد الموقع معطّلة'), findsOneWidget);
    expect(find.text('فتح إعدادات الموقع'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('permission revoked during location fix uses denied message',
      (tester) async {
    location.positionRequest = () =>
        Future.error(const PermissionDeniedException(null));
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('تم رفض إذن الموقع'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('native timeout uses the timeout message', (tester) async {
    location.positionRequest = () => Future.error(TimeoutException('native'));
    await showScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('انتهت مهلة تحديد الموقع'), findsOneWidget);
    expect(requests, isEmpty);
  });
}
