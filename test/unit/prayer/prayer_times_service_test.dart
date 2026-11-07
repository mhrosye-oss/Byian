import 'package:adhan/adhan.dart' as adhan;
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

    test('matches each supported country preset at its GPS coordinates', () async {
      final scenarios = <({
        String country,
        String timeZoneId,
        double latitude,
        double longitude,
        adhan.CalculationMethod method,
        adhan.Madhab madhab,
      })>[
        (
          country: 'Saudi Arabia',
          timeZoneId: 'Asia/Riyadh',
          latitude: 21.4225,
          longitude: 39.8262,
          method: adhan.CalculationMethod.umm_al_qura,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'Egypt',
          timeZoneId: 'Africa/Cairo',
          latitude: 30.0444,
          longitude: 31.2357,
          method: adhan.CalculationMethod.egyptian,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'United Arab Emirates',
          timeZoneId: 'Asia/Dubai',
          latitude: 25.2048,
          longitude: 55.2708,
          method: adhan.CalculationMethod.dubai,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'Qatar',
          timeZoneId: 'Asia/Qatar',
          latitude: 25.2854,
          longitude: 51.5310,
          method: adhan.CalculationMethod.qatar,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'Kuwait',
          timeZoneId: 'Asia/Kuwait',
          latitude: 29.3759,
          longitude: 47.9774,
          method: adhan.CalculationMethod.kuwait,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'Iran',
          timeZoneId: 'Asia/Tehran',
          latitude: 35.6892,
          longitude: 51.3890,
          method: adhan.CalculationMethod.tehran,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'Pakistan',
          timeZoneId: 'Asia/Karachi',
          latitude: 24.8607,
          longitude: 67.0011,
          method: adhan.CalculationMethod.karachi,
          madhab: adhan.Madhab.hanafi,
        ),
        (
          country: 'Indonesia',
          timeZoneId: 'Asia/Jakarta',
          latitude: -6.2088,
          longitude: 106.8456,
          method: adhan.CalculationMethod.singapore,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'Turkey',
          timeZoneId: 'Europe/Istanbul',
          latitude: 41.0082,
          longitude: 28.9784,
          method: adhan.CalculationMethod.turkey,
          madhab: adhan.Madhab.hanafi,
        ),
        (
          country: 'United States',
          timeZoneId: 'America/New_York',
          latitude: 40.7128,
          longitude: -74.0060,
          method: adhan.CalculationMethod.moon_sighting_committee,
          madhab: adhan.Madhab.shafi,
        ),
        (
          country: 'United Kingdom',
          timeZoneId: 'Europe/London',
          latitude: 51.5072,
          longitude: -0.1276,
          method: adhan.CalculationMethod.moon_sighting_committee,
          madhab: adhan.Madhab.shafi,
        ),
      ];

      for (final scenario in scenarios) {
        final prayers = await PrayerTimesService.getTodayPrayerTimes(
          latitude: scenario.latitude,
          longitude: scenario.longitude,
          timeZoneId: scenario.timeZoneId,
        );
        final parameters = scenario.method.getParameters()
          ..madhab = scenario.madhab;
        final expected = adhan.PrayerTimes(
          adhan.Coordinates(scenario.latitude, scenario.longitude),
          adhan.DateComponents.from(DateTime.now()),
          parameters,
        );

        expect(
          prayers.map((prayer) => prayer.time),
          [expected.fajr, expected.dhuhr, expected.asr, expected.maghrib, expected.isha],
          reason: scenario.country,
        );
        expect(prayers, hasLength(5), reason: scenario.country);
        for (var index = 0; index < prayers.length - 1; index++) {
          expect(
            prayers[index].time.isBefore(prayers[index + 1].time),
            isTrue,
            reason: scenario.country,
          );
        }
      }
    });
  });
}
