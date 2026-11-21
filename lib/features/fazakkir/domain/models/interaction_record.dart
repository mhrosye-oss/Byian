/// حالة التذكير وحالة السجل
enum ReminderStatus {
  scheduled, // مجدول وقادم
  delivered, // ظهر كإشعار
  opened, // تم فتح الإشعار
  completed, // تم إنجازه والتفاعل معه («تمّ»)
  snoozed, // مؤجل لموعد لاحق
  skippedInQuiet, // ضمن ساعات الهدوء (تخطي هادئ)
  failed, // تعذر إظهاره (مثل قيود الصلاحيات)
  expired, // انتهى موعده ولم يتم التفاعل معه
}

/// سجل تفاعل فردي لموعد محدد لتذكير
class InteractionRecord {
  final String id;
  final String reminderId;
  final DateTime scheduledTime;
  final DateTime? actionTime;
  final ReminderStatus status;
  final String? note;

  const InteractionRecord({
    required this.id,
    required this.reminderId,
    required this.scheduledTime,
    this.actionTime,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminderId': reminderId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'actionTime': actionTime?.toIso8601String(),
        'status': status.name,
        'note': note,
      };

  factory InteractionRecord.fromJson(Map<String, dynamic> json) {
    return InteractionRecord(
      id: json['id'] as String,
      reminderId: json['reminderId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime']),
      actionTime: json['actionTime'] != null
          ? DateTime.tryParse(json['actionTime'])
          : null,
      status: ReminderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReminderStatus.scheduled,
      ),
      note: json['note'] as String?,
    );
  }

  InteractionRecord copyWith({
    ReminderStatus? status,
    DateTime? actionTime,
    String? note,
  }) {
    return InteractionRecord(
      id: id,
      reminderId: reminderId,
      scheduledTime: scheduledTime,
      actionTime: actionTime ?? this.actionTime,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  String get statusArabic {
    switch (status) {
      case ReminderStatus.scheduled:
        return 'قادم';
      case ReminderStatus.delivered:
        return 'ظهر الإشعار';
      case ReminderStatus.opened:
        return 'تم الفتح';
      case ReminderStatus.completed:
        return 'تمّ';
      case ReminderStatus.snoozed:
        return 'مؤجل';
      case ReminderStatus.skippedInQuiet:
        return 'ضمن الهدوء';
      case ReminderStatus.failed:
        return 'تعذر إظهاره';
      case ReminderStatus.expired:
        return 'فات موعده';
    }
  }
}
