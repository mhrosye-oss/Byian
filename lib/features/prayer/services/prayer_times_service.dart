import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_notification_service.dart';

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

class PrayerTime {
  final PrayerName name;
  final DateTime time;
  final String labelAr;

  const PrayerTime({
    required this.name,
    required this.time,
    required this.labelAr,
  });
}

/// A planned one-shot alert with a stable ID for a prayer and civil date.
class PrayerAlert {
  const PrayerAlert(
      {required this.id,
      required this.prayerName,
      required this.at,
      required this.playAzan,
      required this.payload});
  final int id;
  final String prayerName;
  final DateTime at;
  final bool playAzan;
  final String payload;
}

/// Re-checks the persisted opt-in before and after each platform call. This
/// also removes an alert added concurrently with an opt-out.
@visibleForTesting
Future<void> applyPrayerAlerts(
  Iterable<PrayerAlert> alerts, {
  required Future<bool> Function() isEnabled,
  required Future<void> Function(PrayerAlert) schedule,
  required Future<void> Function(int) cancel,
}) async {
  for (final alert in alerts) {
    if (!await isEnabled()) return;
    await schedule(alert);
    if (!await isEnabled()) {
      await cancel(alert.id);
      return;
    }
  }
}

const _prayerWorkerName = 'prayer-schedule-refresh-v1';
const _prayerEnabledKey = 'prayer_alerts_enabled_v1';

@pragma('vm:entry-point')
void prayerBackgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (task != _prayerWorkerName) return true;
    try {
      await PrayerTimesService.refreshSavedNotifications();
      return true;
    } catch (error, stack) {
      debugPrint('Prayer schedule refresh failed: $error\n$stack');
      return false; // WorkManager may retry; it does not guarantee timing.
    }
  });
}

/// GPS-based prayer calculations and local reminders.
///
/// adhan is a pure-Dart calculation library, so it does not register another
/// Android plugin during Flutter startup. Notification scheduling remains in
/// PrayerNotificationService and uses the bundled `adhan` sound resource.
class PrayerTimesService {
  PrayerTimesService._();

  static const int scheduleDays = 6;
  static const String _latitudeKey = 'prayer_location_latitude';
  static const String _longitudeKey = 'prayer_location_longitude';
  static final PrayerNotificationService _notifications =
      PrayerNotificationService.instance;

  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('خدمة الموقع غير مفعّلة. فعّل GPS ثم أعد المحاولة.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw StateError('لم يُمنح التطبيق إذن الوصول إلى الموقع.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  /// Calculates the five daily prayers. Supplying coordinates avoids a GPS
  /// prompt and is useful for tests or a manually selected city.
  static Future<List<PrayerTime>> getTodayPrayerTimes({
    double? latitude,
    double? longitude,
    String? timeZoneId,
  }) async {
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('latitude and longitude must be supplied together.');
    }

    final adhan.Coordinates coordinates;
    if (latitude != null && longitude != null) {
      coordinates = adhan.Coordinates(latitude, longitude, validate: true);
    } else {
      final position = await getCurrentPosition();
      coordinates = adhan.Coordinates(
        position.latitude,
        position.longitude,
        validate: true,
      );
      await _saveCoordinates(position.latitude, position.longitude);
    }

    final parameters = _parametersForTimeZone(
      timeZoneId ?? await _getDeviceTimeZone(),
    );
    return _prayersForDate(coordinates, DateTime.now(), parameters);
  }

  /// Used by the Home banner without requesting location permission on app
  /// launch. Returns null until the user has opened Prayer Times or enabled
  /// notifications at least once.
  static Future<PrayerTime?> getNextPrayerPreview() async {
    final preferences = await SharedPreferences.getInstance();
    final latitude = preferences.getDouble(_latitudeKey);
    final longitude = preferences.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;

    final coordinates = adhan.Coordinates(latitude, longitude, validate: true);
    final parameters = _parametersForTimeZone(await _getDeviceTimeZone());
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      for (final prayer in _prayersForDate(coordinates, day, parameters)) {
        if (prayer.time.isAfter(now)) return prayer;
      }
    }
    return null;
  }

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Explicit opt-in: GPS and permission prompts happen only in the UI.
  static Future<void> scheduleUpcomingNotifications({
    int days = scheduleDays,
  }) async {
    if (days < 1 || days > scheduleDays) {
      throw ArgumentError.value(days, 'days', 'Must be between 1 and 6.');
    }
    final position = await getCurrentPosition();
    final permissionGranted = await _notifications.requestPermissions();
    if (!permissionGranted) {
      throw StateError(
          'يلزم السماح بالإشعارات والتنبيهات الدقيقة لتفعيل تنبيهات الصلاة.');
    }
    await _saveCoordinates(position.latitude, position.longitude);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_prayerEnabledKey, true);
    try {
      await refreshSavedNotifications(days: days);
      if (_isAndroid) {
        await Workmanager().initialize(prayerBackgroundDispatcher);
        await Workmanager().registerPeriodicTask(
          _prayerWorkerName,
          _prayerWorkerName,
          frequency: const Duration(hours: 12),
          initialDelay: const Duration(hours: 12),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      }
    } catch (_) {
      await disablePrayerNotifications();
      rethrow;
    }
  }

  static Future<bool> prayerNotificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getBool(_prayerEnabledKey) ?? false;
  }

  /// Stops future refresh first and cancels only prayer-owned notifications.
  static Future<void> disablePrayerNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_prayerEnabledKey, false);
    try {
      if (_isAndroid) await Workmanager().cancelByUniqueName(_prayerWorkerName);
    } finally {
      // A failed WorkManager cancellation must not leave existing alerts armed.
      await _notifications.cancelPrayerNotifications();
    }
  }

  /// Background refresh uses cached coordinates; no GPS or permission prompts.
  static Future<void> refreshSavedNotifications(
      {int days = scheduleDays}) async {
    if (!await prayerNotificationsEnabled()) return;
    if (!await _notifications.canSchedulePrayerAlerts()) {
      throw StateError('إذن الإشعارات أو التنبيهات الدقيقة غير متاح.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final latitude = preferences.getDouble(_latitudeKey);
    final longitude = preferences.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) {
      throw StateError('الموقع المحفوظ غير متاح لإعداد التنبيهات.');
    }
    final alerts = planPrayerAlerts(
      latitude: latitude,
      longitude: longitude,
      timeZoneId: await _getDeviceTimeZone(),
      now: DateTime.now(),
      days: days,
    );
    await applyPrayerAlerts(
      alerts,
      isEnabled: prayerNotificationsEnabled,
      schedule: (alert) => _notifications.schedulePrayer(
        id: alert.id,
        prayerName: alert.prayerName,
        at: alert.at,
        playAzan: alert.playAzan,
        payload: alert.payload,
      ),
      cancel: _notifications.cancelPrayerNotification,
    );
  }

  /// Pure calculation, allowing deterministic tests without GPS or plugins.
  @visibleForTesting
  static List<PrayerAlert> planPrayerAlerts({
    required double latitude,
    required double longitude,
    required String timeZoneId,
    required DateTime now,
    int days = scheduleDays,
  }) {
    if (days < 1 || days > scheduleDays) {
      throw ArgumentError.value(days, 'days', 'Must be between 1 and 6.');
    }
    final coordinates = adhan.Coordinates(latitude, longitude, validate: true);
    final parameters = _parametersForTimeZone(timeZoneId);
    final alerts = <PrayerAlert>[];
    for (var offset = 0; offset < days; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      final prayers = _prayersForDate(coordinates, day, parameters);
      for (var index = 0; index < prayers.length; index++) {
        final prayer = prayers[index];
        final id = _notificationId(day, index);
        final reminder = prayer.time.subtract(const Duration(minutes: 15));
        if (reminder.isAfter(now)) {
          alerts.add(PrayerAlert(
              id: id,
              prayerName: prayer.labelAr,
              at: reminder,
              playAzan: false,
              payload: 'prayer:${day.toIso8601String()}:$index:before'));
        }
        if (prayer.time.isAfter(now)) {
          alerts.add(PrayerAlert(
              id: id + 1,
              prayerName: prayer.labelAr,
              at: prayer.time,
              playAzan: true,
              payload: 'prayer:${day.toIso8601String()}:$index:adhan'));
        }
      }
    }
    return alerts;
  }

  static List<PrayerTime> _prayersForDate(
    adhan.Coordinates coordinates,
    DateTime date,
    adhan.CalculationParameters parameters,
  ) {
    final times = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents.from(date),
      parameters,
    );

    return [
      PrayerTime(name: PrayerName.fajr, time: times.fajr, labelAr: 'الفجر'),
      PrayerTime(name: PrayerName.dhuhr, time: times.dhuhr, labelAr: 'الظهر'),
      PrayerTime(name: PrayerName.asr, time: times.asr, labelAr: 'العصر'),
      PrayerTime(
          name: PrayerName.maghrib, time: times.maghrib, labelAr: 'المغرب'),
      PrayerTime(name: PrayerName.isha, time: times.isha, labelAr: 'العشاء'),
    ];
  }

  static Future<String> _getDeviceTimeZone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      // Prayer calculations can still use the system-local time if the
      // timezone plugin is unavailable; country-specific defaults then fall
      // back to Muslim World League.
      return DateTime.now().timeZoneName;
    }
  }

  static adhan.CalculationParameters _parametersForTimeZone(String timeZoneId) {
    final zone = timeZoneId.trim().toLowerCase();
    var method = adhan.CalculationMethod.muslim_world_league;
    var madhab = adhan.Madhab.shafi;

    if (zone == 'asia/riyadh') {
      method = adhan.CalculationMethod.umm_al_qura;
    } else if (zone == 'africa/cairo') {
      method = adhan.CalculationMethod.egyptian;
    } else if (zone == 'asia/dubai') {
      method = adhan.CalculationMethod.dubai;
    } else if (zone == 'asia/qatar') {
      method = adhan.CalculationMethod.qatar;
    } else if (zone == 'asia/kuwait') {
      method = adhan.CalculationMethod.kuwait;
    } else if (zone == 'asia/tehran') {
      method = adhan.CalculationMethod.tehran;
    } else if (zone == 'asia/karachi' ||
        zone == 'asia/kolkata' ||
        zone == 'asia/calcutta' ||
        zone == 'asia/dhaka') {
      method = adhan.CalculationMethod.karachi;
      madhab = adhan.Madhab.hanafi;
    } else if (zone == 'asia/singapore' ||
        zone == 'asia/kuala_lumpur' ||
        zone == 'asia/kuching' ||
        zone == 'asia/jakarta' ||
        zone == 'asia/pontianak' ||
        zone == 'asia/makassar' ||
        zone == 'asia/jayapura' ||
        zone == 'asia/brunei') {
      method = adhan.CalculationMethod.singapore;
    } else if (zone == 'europe/istanbul') {
      method = adhan.CalculationMethod.turkey;
      madhab = adhan.Madhab.hanafi;
    } else if (zone.startsWith('america/') ||
        zone.startsWith('canada/') ||
        zone == 'europe/london' ||
        zone == 'europe/belfast') {
      method = adhan.CalculationMethod.moon_sighting_committee;
    }

    return method.getParameters()..madhab = madhab;
  }

  static Future<void> _saveCoordinates(
      double latitude, double longitude) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_latitudeKey, latitude);
    await preferences.setDouble(_longitudeKey, longitude);
  }

  static int _notificationId(DateTime day, int prayerIndex) {
    final dateKey = day.year * 10000 + day.month * 100 + day.day;
    return dateKey * 10 + prayerIndex * 2;
  }
}
