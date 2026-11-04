import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Owns only prayer notification channels, leaving other app notifications intact.
class PrayerNotificationService {
  PrayerNotificationService._();

  static final PrayerNotificationService instance =
      PrayerNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Requests only the permissions needed for visible and exact prayer alerts.
  Future<bool> requestPermissions() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notificationsGranted =
          await android.requestNotificationsPermission();
      final exactAlarmsGranted = await android.requestExactAlarmsPermission();
      return notificationsGranted != false && exactAlarmsGranted != false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<void> cancelPrayerNotifications() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith('prayer:') ?? false) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime at,
    required bool playAzan,
    required String payload,
  }) async {
    await initialize();
    final androidDetails = AndroidNotificationDetails(
      playAzan ? 'prayer_azan_v1' : 'prayer_reminder_v1',
      playAzan ? 'أذان الصلاة' : 'تذكير الصلاة',
      channelDescription: playAzan
          ? 'تنبيه عند دخول وقت الصلاة بصوت أذان قصير'
          : 'تنبيه قبل دخول وقت الصلاة بخمس عشرة دقيقة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playAzan,
      sound: playAzan ? const RawResourceAndroidNotificationSound('adhan') : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: playAzan,
      sound: playAzan ? 'adhan.caf' : null,
    );

    await _plugin.zonedSchedule(
      id,
      playAzan ? 'حان وقت صلاة $prayerName' : 'اقترب وقت صلاة $prayerName',
      playAzan ? 'حيّ على الصلاة' : 'بقي 15 دقيقة على الصلاة',
      tz.TZDateTime.from(at, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
