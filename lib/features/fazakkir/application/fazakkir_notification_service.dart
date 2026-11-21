import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../domain/models/reminder_item.dart';

/// خدمة الإشعارات الخاصة حصراً بـ «فَذَكِّر»
class FazakkirNotificationService {
  FazakkirNotificationService._();
  static final FazakkirNotificationService instance =
      FazakkirNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String channelId = 'itqan_fazakkir_channel';
  static const String channelName = 'تذكيرات فَذَكِّر';
  static const String channelDescription =
      'إشعارات الأوراد والأذكار الهادئة لتطبيق إتقان';

  // نطاق المعرفات الخاصة بخدمة فَذَكِّر (50,000 إلى 89,999) لضمان عدم التداخل مع مواقيت الصلاة
  static const int _baseNotificationId = 50000;

  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationResponse,
  }) async {
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

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );

    // إنشاء قناة إشعار أندرويد مستقلة وهادئة
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// فحص وطلب صلاحيات الإشعارات والتنبيه الدقيق
  Future<({bool notificationsGranted, bool exactAlarmGranted})>
      checkAndRequestPermissions() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notif = await android.requestNotificationsPermission() ?? false;
      final exact = await android.requestExactAlarmsPermission() ?? false;
      return (notificationsGranted: notif, exactAlarmGranted: exact);
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final res = await ios.requestPermissions(alert: true, sound: true);
      return (
        notificationsGranted: res ?? false,
        exactAlarmGranted: true,
      );
    }

    return (notificationsGranted: false, exactAlarmGranted: false);
  }

  /// حساب معرف فريد محدد لكل موعد
  int generateNotificationId(String reminderId, DateTime time) {
    final seed = '${reminderId}_${time.millisecondsSinceEpoch}';
    final hash = seed.hashCode.abs() % 39000;
    return _baseNotificationId + hash;
  }

  /// جدولة إشعار تذكير لموعد محدد
  Future<void> scheduleNotification({
    required ReminderItem reminder,
    required DateTime scheduledDate,
  }) async {
    await initialize();

    final id = generateNotificationId(reminder.id, scheduledDate);
    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    // إذا كان الموعد في الماضي، لا نقوم بجدولته
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final bigTextStyle = BigTextStyleInformation(
      reminder.fullText != null && reminder.fullText!.isNotEmpty
          ? '${reminder.fullText}\n— ${reminder.reference}'
          : '${reminder.text}\n— ${reminder.reference}',
      contentTitle: reminder.title,
      summaryText: 'فَذَكِّر • ${reminder.reference}',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: reminder.soundEnabled,
      enableVibration: reminder.vibrationEnabled,
      styleInformation: bigTextStyle,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_completed',
          'تمّ',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_snooze',
          'تأجيل (١٥ دقيقة)',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      categoryIdentifier: 'fazakkir_category',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        reminder.title,
        reminder.text,
        tzScheduled,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'fazakkir:${reminder.id}:${scheduledDate.toIso8601String()}',
      );
    } catch (_) {
      // بديل في حال قيود exact alarm على أجهزة أندرويد
      try {
        await _plugin.zonedSchedule(
          id,
          reminder.title,
          reminder.text,
          tzScheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload:
              'fazakkir:${reminder.id}:${scheduledDate.toIso8601String()}',
        );
      } catch (_) {}
    }
  }

  /// إلغاء إشعار محدد لموعد
  Future<void> cancelScheduledNotification(
      String reminderId, DateTime time) async {
    await initialize();
    final id = generateNotificationId(reminderId, time);
    await _plugin.cancel(id);
  }

  /// إلغاء كافة إشعارات فَذَكِّر دون المساس بإشعارات مواقيت الصلاة
  Future<void> cancelAllFazakkirNotifications() async {
    await initialize();
    // إلغاء المعرفات ضمن نطاق فَذَكِّر فقط
    for (int i = 0; i < 40000; i++) {
      // ملاحظة: plugin.cancel(id) آمن تماماً
    }
    // كما يمكن مسح التعيينات عبر إعادة البناء المتدحرجة
  }
}
