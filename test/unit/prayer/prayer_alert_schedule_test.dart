import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/prayer/services/prayer_times_service.dart';

void main() {
  final now = DateTime(2026, 3, 15, 0);
  List<PrayerAlert> plan({int days = 6, DateTime? start}) =>
      PrayerTimesService.planPrayerAlerts(
        latitude: 24.7136,
        longitude: 46.6753,
        timeZoneId: 'Asia/Riyadh',
        now: start ?? now,
        days: days,
      );

  test('plans future alerts with unique stable IDs and 15-minute reminders',
      () {
    final alerts = plan();
    final ids = alerts.map((a) => a.id).toList();
    expect(alerts.length, lessThanOrEqualTo(60));
    expect(alerts.length, greaterThan(40));
    expect(ids.toSet().length, ids.length);
    expect(ids, plan().map((a) => a.id));
    expect(alerts.every((a) => a.at.isAfter(now)), isTrue);
    for (final adhan in alerts.where((a) => a.playAzan)) {
      final reminder = alerts.where((a) => a.id == adhan.id - 1).toList();
      if (reminder.isNotEmpty) {
        expect(adhan.at.difference(reminder.single.at),
            const Duration(minutes: 15));
        expect(reminder.single.playAzan, isFalse);
        expect(reminder.single.prayerName, adhan.prayerName);
      }
    }
  });

  test('omits past times and validates horizon', () {
    final dayAlerts = plan(days: 1);
    final afterFirst = dayAlerts.first.at.add(const Duration(seconds: 1));
    expect(
        plan(days: 1, start: afterFirst).any((a) => a.id == dayAlerts.first.id),
        isFalse);
    expect(() => plan(days: 0), throwsArgumentError);
    expect(() => plan(days: 7), throwsArgumentError);
  });

  test('repeated application uses stable IDs and does not touch other IDs',
      () async {
    final pending = <int, PrayerAlert>{
      9999: PrayerAlert(
          id: 9999, prayerName: 'other', at: now, playAzan: false, payload: '')
    };
    final alerts = plan(days: 1);
    Future<void> run() => applyPrayerAlerts(
          alerts,
          isEnabled: () async => true,
          schedule: (a) async {
            pending[a.id] = a;
          },
          cancel: (id) async {
            pending.remove(id);
          },
        );
    await run();
    await run();
    expect(pending.length, alerts.length + 1);
    expect(pending.containsKey(9999), isTrue);
  });

  test('opt-out during scheduling removes in-flight alert and stops', () async {
    var enabled = true;
    final scheduled = <int>[];
    final cancelled = <int>[];
    await applyPrayerAlerts(
      plan(days: 1),
      isEnabled: () async => enabled,
      schedule: (a) async {
        scheduled.add(a.id);
        enabled = false;
      },
      cancel: (id) async {
        cancelled.add(id);
      },
    );
    expect(scheduled.length, 1);
    expect(cancelled, scheduled);
  });

  test('schedule errors are surfaced for retry instead of reported as success',
      () async {
    await expectLater(
      applyPrayerAlerts(
        plan(days: 1),
        isEnabled: () async => true,
        schedule: (_) async => throw StateError('platform scheduling failed'),
        cancel: (_) async {},
      ),
      throwsStateError,
    );
  });
}
