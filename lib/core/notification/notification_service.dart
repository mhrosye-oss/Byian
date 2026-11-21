import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _prayerChannelId = 'prayer_times_v2';
  static const String _systemChannelId = 'system_events_v2';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // تهيئة المناطق الزمنية
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // احتياطي في حال تعذر الحصول على المنطقة الزمنية
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _plugin.initialize(initializationSettings);
    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      _prayerChannelId,
      'مواقيت الصلاة والأذان',
      description: 'إشعارات الأذان وتذكيرات مواقيت الصلوات الخمس',
      importance: Importance.max,
      playSound: true,
    );
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      _systemChannelId,
      'إشعارات النظام والرسائل',
      description: 'إشعارات الحلقات والهمسات وتحديثات التطبيق العامة',
      importance: Importance.high,
      playSound: true,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(prayerChannel);
    await android?.createNotificationChannel(systemChannel);
  }

  /// جدولة إشعار لمواقيت الصلاة اليومية
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool playSound = true,
  }) async {
    await init();
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'مواقيت الصلاة والأذان',
          channelDescription: 'إشعارات الأذان وتذكيرات مواقيت الصلوات الخمس',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// إشعار فوري من نظام (Firebase) أو أي مصدر آخر
  Future<void> showSystemNotification({
    int id = 9999,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _systemChannelId,
          'إشعارات النظام والرسائل',
          channelDescription: 'إشعارات الحلقات والهمسات وتحديثات التطبيق العامة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
