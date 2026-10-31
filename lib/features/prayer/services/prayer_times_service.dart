import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

class PrayerTime {
  final PrayerName name;
  final DateTime time;
  final String labelAr;
  const PrayerTime({required this.name, required this.time, required this.labelAr});
}

class PrayerTimesService {
  static final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestSoundPermission: true, requestBadgePermission: true, requestAlertPermission: true);
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await notifications.initialize(initSettings);
  }

  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('خدمة الموقع غير مفعلة');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) throw Exception('تم رفض صلاحية الموقع بشكل دائم');
    if (permission == LocationPermission.denied) throw Exception('تم رفض صلاحية الموقع');
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
  }

  static Future<List<PrayerTime>> getTodayPrayerTimes({double? latitude, double? longitude}) async {
    final pos = (latitude == null || longitude == null) ? await getCurrentPosition() : Position(latitude: latitude, longitude: longitude, timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0, floor: null, isMocked: false);
    final coords = Coordinates(pos.latitude, pos.longitude);
    final params = CalculationMethod.muslimWorldLeague();
    final prayerTimes = PrayerTimes.today(coords, params);
    final now = DateTime.now();
    
    return [
      PrayerTime(name: PrayerName.fajr, time: _normalizeDate(prayerTimes.fajr, now), labelAr: 'الفجر'),
      PrayerTime(name: PrayerName.dhuhr, time: _normalizeDate(prayerTimes.dhuhr, now), labelAr: 'الظهر'),
      PrayerTime(name: PrayerName.asr, time: _normalizeDate(prayerTimes.asr, now), labelAr: 'العصر'),
      PrayerTime(name: PrayerName.maghrib, time: _normalizeDate(prayerTimes.maghrib, now), labelAr: 'المغرب'),
      PrayerTime(name: PrayerName.isha, time: _normalizeDate(prayerTimes.isha, now), labelAr: 'العشاء'),
    ];
  }

  static DateTime _normalizeDate(DateTime prayerTime, DateTime today) {
    return DateTime(today.year, today.month, today.day, prayerTime.hour, prayerTime.minute, prayerTime.second);
  }
}
