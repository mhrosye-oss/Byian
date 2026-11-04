import 'package:adhan/adhan.dart' as adhan;
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

    return _prayersForDate(coordinates, DateTime.now());
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
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      for (final prayer in _prayersForDate(coordinates, day)) {
        if (prayer.time.isAfter(now)) return prayer;
      }
    }
    return null;
  }

  /// Rebuilds up to six days of notifications: 15-minute reminder plus exact
  /// prayer-time notification with the custom Azan sound.
  static Future<void> scheduleUpcomingNotifications({
    int days = scheduleDays,
  }) async {
    if (days < 1 || days > 6) {
      throw ArgumentError.value(days, 'days', 'Must be between 1 and 6.');
    }

    final position = await getCurrentPosition();
    await _saveCoordinates(position.latitude, position.longitude);
    final coordinates = adhan.Coordinates(
      position.latitude,
      position.longitude,
      validate: true,
    );

    final permissionGranted = await _notifications.requestPermissions();
    if (!permissionGranted) {
      throw StateError(
        'يلزم السماح بالإشعارات والتنبيهات الدقيقة لتفعيل أذان الصلاة.',
      );
    }

    await _notifications.cancelPrayerNotifications();
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < days; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      final prayers = _prayersForDate(coordinates, day);

      for (var index = 0; index < prayers.length; index++) {
        final prayer = prayers[index];
        final baseId = _notificationId(day, index);
        final reminderTime = prayer.time.subtract(const Duration(minutes: 15));

        if (reminderTime.isAfter(now)) {
          await _notifications.schedulePrayer(
            id: baseId,
            prayerName: prayer.labelAr,
            at: reminderTime,
            playAzan: false,
            payload: 'prayer:${day.toIso8601String()}:$index:before',
          );
        }
        if (prayer.time.isAfter(now)) {
          await _notifications.schedulePrayer(
            id: baseId + 1,
            prayerName: prayer.labelAr,
            at: prayer.time,
            playAzan: true,
            payload: 'prayer:${day.toIso8601String()}:$index:adhan',
          );
        }
      }
    }
  }

  static List<PrayerTime> _prayersForDate(
    adhan.Coordinates coordinates,
    DateTime date,
  ) {
    final parameters = adhan.CalculationMethod.muslim_world_league
        .getParameters()
      ..madhab = adhan.Madhab.shafi;
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
