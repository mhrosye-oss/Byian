import 'package:flutter/material.dart';

enum QuietHoursAction {
  skip, // تخطي الإشعار وتسجيل الحالة كـ "ضمن الهدوء"
  postponeAfterQuiet, // تأجيل الإشعار تلقائياً لما بعد نهاية ساعات الهدوء
}

/// إعدادات ساعات الهدوء المخصصة لمنع الإزعاج في فترات الراحة أو النوم
class QuietHoursSettings {
  final bool isEnabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> activeDays; // 1 = Monday .. 7 = Sunday
  final QuietHoursAction action;
  final List<String> exceptionReminderIds; // استثناءات يسمح بها المستخدم

  const QuietHoursSettings({
    this.isEnabled = true,
    this.startTime = const TimeOfDay(hour: 23, minute: 0), // 11:00 PM
    this.endTime = const TimeOfDay(hour: 5, minute: 30), // 5:30 AM
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7], // كل الأيام افتراضياً
    this.action = QuietHoursAction.postponeAfterQuiet,
    this.exceptionReminderIds = const [],
  });

  bool isInQuietHours(DateTime dateTime) {
    if (!isEnabled) return false;
    if (!activeDays.contains(dateTime.weekday)) return false;

    final targetMinutes = dateTime.hour * 60 + dateTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // نفس اليوم (مثلاً 1:00 ظهر إلى 3:00 عصر)
      return targetMinutes >= startMinutes && targetMinutes <= endMinutes;
    } else {
      // تعبر منتصف الليل (مثلاً 23:00 إلى 05:30)
      return targetMinutes >= startMinutes || targetMinutes <= endMinutes;
    }
  }

  /// يحسب الموعد المؤجل إذا كان الوقت يقع في ساعات الهدوء
  DateTime resolveScheduledTime(DateTime scheduled) {
    if (!isInQuietHours(scheduled)) return scheduled;

    if (action == QuietHoursAction.postponeAfterQuiet) {
      // إعادة الجدولة مباشرة عند نهاية ساعات الهدوء + 10 دقائق هادئة
      DateTime next = DateTime(
        scheduled.year,
        scheduled.month,
        scheduled.day,
        endTime.hour,
        endTime.minute + 10,
      );
      if (next.isBefore(scheduled)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    }
    return scheduled;
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'activeDays': activeDays,
        'action': action.name,
        'exceptionReminderIds': exceptionReminderIds,
      };

  factory QuietHoursSettings.fromJson(Map<String, dynamic> json) {
    return QuietHoursSettings(
      isEnabled: json['isEnabled'] as bool? ?? true,
      startTime: TimeOfDay(
        hour: json['startHour'] as int? ?? 23,
        minute: json['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int? ?? 5,
        minute: json['endMinute'] as int? ?? 30,
      ),
      activeDays: (json['activeDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      action: QuietHoursAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => QuietHoursAction.postponeAfterQuiet,
      ),
      exceptionReminderIds: (json['exceptionReminderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  QuietHoursSettings copyWith({
    bool? isEnabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? activeDays,
    QuietHoursAction? action,
    List<String>? exceptionReminderIds,
  }) {
    return QuietHoursSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activeDays: activeDays ?? this.activeDays,
      action: action ?? this.action,
      exceptionReminderIds: exceptionReminderIds ?? this.exceptionReminderIds,
    );
  }
}
