import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/prayer/services/prayer_times_service.dart';

void main() {
  group('PrayerTimesService', () {
    test('calculates five ordered daily prayers for explicit coordinates',
        () async {
      final prayers = await PrayerTimesService.getTodayPrayerTimes(
        latitude: 21.4225,
        longitude: 39.8262,
        timeZoneId: 'Asia/Riyadh',
      );

      expect(prayers, hasLength(5));
      expect(prayers.map((prayer) => prayer.labelAr), [
        'الفجر',
        'الظهر',
        'العصر',
        'المغرب',
        'العشاء',
      ]);
      for (var index = 0; index < prayers.length - 1; index++) {
        expect(prayers[index].time.isBefore(prayers[index + 1].time), isTrue);
      }
    });

    test('uses country-specific calculation parameters', () async {
      final makkah = await PrayerTimesService.getTodayPrayerTimes(
        latitude: 21.4225,
        longitude: 39.8262,
        timeZoneId: 'Asia/Riyadh',
      );
      final cairo = await PrayerTimesService.getTodayPrayerTimes(
        latitude: 21.4225,
        longitude: 39.8262,
        timeZoneId: 'Africa/Cairo',
      );

      expect(makkah.last.time, isNot(cairo.last.time));
    });
  });
}
