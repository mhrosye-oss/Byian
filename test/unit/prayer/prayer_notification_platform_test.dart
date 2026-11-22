import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/prayer/services/prayer_notification_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const notifications =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const timezone = MethodChannel('flutter_timezone');
  final calls = <MethodCall>[];
  var notificationsAllowed = true;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(timezone, (call) async => 'Asia/Riyadh');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(notifications,
        (call) async {
      calls.add(call);
      switch (call.method) {
        case 'requestNotificationsPermission':
          return notificationsAllowed;
        case 'requestExactAlarmsPermission':
          return true;
        case 'initialize':
        case 'areNotificationsEnabled':
        case 'canScheduleExactNotifications':
          return true;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(timezone, null);
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(notifications, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('notification denial does not request the exact alarm permission',
      () async {
    calls.clear();
    notificationsAllowed = false;
    expect(
        await PrayerNotificationService.instance.requestPermissions(), isFalse);
    expect(
        calls.any((c) => c.method == 'requestExactAlarmsPermission'), isFalse);
    notificationsAllowed = true;
    calls.clear();
  });

  test('background permission check does not prompt; adhan uses raw audio',
      () async {
    final service = PrayerNotificationService.instance;
    expect(await service.canSchedulePrayerAlerts(), isTrue);
    expect(calls.any((c) => c.method.startsWith('request')), isFalse);
    await service.schedulePrayer(
      id: 2026112201,
      prayerName: 'الفجر',
      at: DateTime.now().add(const Duration(hours: 1)),
      playAzan: true,
      payload: 'prayer:test',
    );
    final scheduled = calls.lastWhere((c) => c.method == 'zonedSchedule');
    final args = scheduled.arguments as Map<Object?, Object?>;
    final details = args['platformSpecifics'] as Map<Object?, Object?>;
    expect(details['sound'], 'adhan');
    expect(details['channelId'], 'prayer_azan_excerpt_v2');
    expect(details['playSound'], isTrue);
    expect(details['scheduleMode'], 'exactAllowWhileIdle');
  });
}
