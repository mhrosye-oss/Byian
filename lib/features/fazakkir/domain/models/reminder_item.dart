import 'package:flutter/material.dart';
import 'recurrence_rule.dart';
import 'reminder_type.dart';

/// كائن التذكير المستقل داخل خدمة «فَذَكِّر»
class ReminderItem {
  final String id;
  final String? programId;
  final ReminderTypeCategory category;
  final String title;
  final String text; // نص الذكر أو مقتطفه المعتمد
  final String? fullText; // النص الموسع للإشعار وتفاصيل الذكر
  final String reference; // المرجع والمصدر الموثق من مكتبة إتقان
  final RecurrenceRule recurrenceRule;
  final List<TimeOfDay> targetTimes; // مواعيد اليوم المحددة
  final bool isActive;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;
  final DateTime? snoozeUntil;

  const ReminderItem({
    required this.id,
    this.programId,
    required this.category,
    required this.title,
    required this.text,
    this.fullText,
    required this.reference,
    required this.recurrenceRule,
    required this.targetTimes,
    this.isActive = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    required this.createdAt,
    this.lastTriggeredAt,
    this.snoozeUntil,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'category': category.name,
        'title': title,
        'text': text,
        'fullText': fullText,
        'reference': reference,
        'recurrenceRule': recurrenceRule.toJson(),
        'targetTimes': targetTimes
            .map((t) => {'hour': t.hour, 'minute': t.minute})
            .toList(),
        'isActive': isActive,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'createdAt': createdAt.toIso8601String(),
        'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
        'snoozeUntil': snoozeUntil?.toIso8601String(),
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String,
      programId: json['programId'] as String?,
      category: ReminderTypeCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ReminderTypeCategory.morningEvening,
      ),
      title: json['title'] as String,
      text: json['text'] as String,
      fullText: json['fullText'] as String?,
      reference: json['reference'] as String? ?? 'مكتبة إتقان المعتمدة',
      recurrenceRule: RecurrenceRule.fromJson(
        Map<String, dynamic>.from(json['recurrenceRule']),
      ),
      targetTimes: (json['targetTimes'] as List<dynamic>?)
              ?.map((t) => TimeOfDay(
                    hour: t['hour'] as int,
                    minute: t['minute'] as int,
                  ))
              .toList() ??
          const [TimeOfDay(hour: 8, minute: 0)],
      isActive: json['isActive'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggeredAt: json['lastTriggeredAt'] != null
          ? DateTime.tryParse(json['lastTriggeredAt'])
          : null,
      snoozeUntil: json['snoozeUntil'] != null
          ? DateTime.tryParse(json['snoozeUntil'])
          : null,
    );
  }

  ReminderItem copyWith({
    String? programId,
    ReminderTypeCategory? category,
    String? title,
    String? text,
    String? fullText,
    String? reference,
    RecurrenceRule? recurrenceRule,
    List<TimeOfDay>? targetTimes,
    bool? isActive,
    bool? soundEnabled,
    bool? vibrationEnabled,
    DateTime? lastTriggeredAt,
    DateTime? snoozeUntil,
  }) {
    return ReminderItem(
      id: id,
      programId: programId ?? this.programId,
      category: category ?? this.category,
      title: title ?? this.title,
      text: text ?? this.text,
      fullText: fullText ?? this.fullText,
      reference: reference ?? this.reference,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      targetTimes: targetTimes ?? this.targetTimes,
      isActive: isActive ?? this.isActive,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      createdAt: createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
    );
  }
}
