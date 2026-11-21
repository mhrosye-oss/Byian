import '../data/fazakkir_repository.dart';
import '../domain/models/interaction_record.dart';
import '../domain/models/quiet_hours.dart';
import '../domain/models/recurrence_rule.dart';
import '../domain/models/reminder_item.dart';
import 'fazakkir_notification_service.dart';

class ScheduledOccurrence {
  final ReminderItem reminder;
  final DateTime scheduledTime;
  final bool isInQuietHours;
  final DateTime resolvedTime;

  const ScheduledOccurrence({
    required this.reminder,
    required this.scheduledTime,
    required this.isInQuietHours,
    required this.resolvedTime,
  });
}

/// محرك الجدولة المتدحرجة المستقل (Idempotent Rolling Scheduler - 72 ساعة)
class SchedulingEngine {
  final FazakkirRepository _repository;
  final FazakkirNotificationService _notificationService;

  SchedulingEngine({
    FazakkirRepository? repository,
    FazakkirNotificationService? notificationService,
  })  : _repository = repository ?? FazakkirRepository.instance,
        _notificationService =
            notificationService ?? FazakkirNotificationService.instance;

  /// اشتقاق المواعيد القادمة لتذكير محدد خلال نافذة زمنية (ساعات)
  List<DateTime> calculateOccurrences({
    required ReminderItem reminder,
    required DateTime from,
    Duration window = const Duration(hours: 72),
  }) {
    if (!reminder.isActive) return [];

    final occurrences = <DateTime>[];
    final until = from.add(window);
    final rule = reminder.recurrenceRule;

    // التحقق من حدود التاريخ العامة
    if (rule.endDate != null && from.isAfter(rule.endDate!)) return [];

    // التكرار عبر الأيام ضمن النافذة
    DateTime cursor = DateTime(from.year, from.month, from.day);
    while (cursor.isBefore(until)) {
      if (rule.startDate != null && cursor.isBefore(DateTime(rule.startDate!.year, rule.startDate!.month, rule.startDate!.day))) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }
      if (rule.endDate != null && cursor.isAfter(rule.endDate!)) {
        break;
      }

      bool isMatch = false;

      switch (rule.frequency) {
        case RecurrenceFrequency.once:
          isMatch = cursor.year == from.year &&
              cursor.month == from.month &&
              cursor.day == from.day;
          break;

        case RecurrenceFrequency.daily:
          isMatch = true;
          break;

        case RecurrenceFrequency.everyXHours:
          // سيتم اشتقاق الساعات لاحقاً لكل هدف
          isMatch = true;
          break;

        case RecurrenceFrequency.specificWeekdays:
          isMatch = rule.weekdays.contains(cursor.weekday);
          break;

        case RecurrenceFrequency.weekly:
          isMatch = (rule.weekdays.isNotEmpty)
              ? rule.weekdays.contains(cursor.weekday)
              : cursor.weekday == DateTime.friday;
          break;

        case RecurrenceFrequency.biweekly:
          final diffWeeks = cursor.difference(from).inDays ~/ 7;
          isMatch = (diffWeeks % 2 == 0) &&
              (rule.weekdays.isEmpty || rule.weekdays.contains(cursor.weekday));
          break;

        case RecurrenceFrequency.monthlyDay:
          isMatch = (rule.monthDay != null && cursor.day == rule.monthDay);
          break;

        case RecurrenceFrequency.firstFridayOfMonth:
          if (cursor.weekday == DateTime.friday && cursor.day <= 7) {
            isMatch = true;
          }
          break;
      }

      if (isMatch) {
        for (final targetTime in reminder.targetTimes) {
          final candidate = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            targetTime.hour,
            targetTime.minute,
          );

          if (candidate.isAfter(from) && candidate.isBefore(until)) {
            occurrences.add(candidate);
          }
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    // إذا كان هناك تأجيل يدوي نشط
    if (reminder.snoozeUntil != null && reminder.snoozeUntil!.isAfter(from)) {
      occurrences.insert(0, reminder.snoozeUntil!);
    }

    occurrences.sort();
    return occurrences;
  }

  /// إعادة بناء المواعيد لجميع التذكيرات النشطة وجدولة الإشعارات الحقيقية
  Future<List<ScheduledOccurrence>> rebuildSchedule({
    Duration window = const Duration(hours: 72),
  }) async {
    final now = DateTime.now();
    final reminders = await _repository.getReminders();
    final programs = await _repository.getPrograms();
    final quietHours = await _repository.getQuietHours();

    // خريطة البرامج المعلقة
    final pausedProgramIds = programs
        .where((p) => p.isPaused)
        .map((p) => p.id)
        .toSet();

    final scheduledList = <ScheduledOccurrence>[];

    for (final reminder in reminders) {
      if (!reminder.isActive) continue;
      // إذا كان البرنامج التابع له موقوفاً مؤقتاً
      if (reminder.programId != null &&
          pausedProgramIds.contains(reminder.programId)) {
        continue;
      }

      final occurrences = calculateOccurrences(
        reminder: reminder,
        from: now,
        window: window,
      );

      for (final occ in occurrences) {
        final isInQuiet = quietHours.isInQuietHours(occ);
        final resolvedTime = quietHours.resolveScheduledTime(occ);

        // إذا كان ضمن ساعات الهدوء والقرار تخطي، نسجل الحالة ولا نجدول إشعاراً
        if (isInQuiet && quietHours.action == QuietHoursAction.skip) {
          final record = InteractionRecord(
            id: 'quiet_${reminder.id}_${occ.millisecondsSinceEpoch}',
            reminderId: reminder.id,
            scheduledTime: occ,
            status: ReminderStatus.skippedInQuiet,
            note: 'تم التخطي احتراماً لساعات الهدوء',
          );
          await _repository.saveRecord(record);
          continue;
        }

        scheduledList.add(ScheduledOccurrence(
          reminder: reminder,
          scheduledTime: occ,
          isInQuietHours: isInQuiet,
          resolvedTime: resolvedTime,
        ));

        // جدولة الإشعار الحقيقي في النظام
        await _notificationService.scheduleNotification(
          reminder: reminder,
          scheduledDate: resolvedTime,
        );
      }
    }

    // حفظ تاريخ آخر إعادة بناء ناجحة
    await _repository.setLastRebuildTime(now);

    scheduledList.sort((a, b) => a.resolvedTime.compareTo(b.resolvedTime));
    return scheduledList;
  }
}
