/// نمط تكرار التذكير
enum RecurrenceFrequency {
  once, // مرة واحدة
  daily, // يومياً
  everyXHours, // كل عدد معين من الساعات
  specificWeekdays, // أيام محددة من الأسبوع
  weekly, // أسبوعياً
  biweekly, // كل أسبوعين
  monthlyDay, // يوم محدد من الشهر
  firstFridayOfMonth, // أول جمعة من الشهر
}

/// قاعدة التكرار المستقلة (يفصل منطق التكرار عن المواعيد المحسوبة)
class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval; // مثلاً كل 3 ساعات أو كل 2 أسابيع
  final List<int> weekdays; // 1 = الإثنين, 7 = الأحد (DateTime.monday .. sunday)
  final int? monthDay; // رقم اليوم في الشهر (1-31)
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxOccurrences; // حد أقصى للتكرار إن وجد

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.monthDay,
    this.startDate,
    this.endDate,
    this.maxOccurrences,
  });

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        'interval': interval,
        'weekdays': weekdays,
        'monthDay': monthDay,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'maxOccurrences': maxOccurrences,
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurrenceFrequency.daily,
      ),
      interval: json['interval'] as int? ?? 1,
      weekdays: (json['weekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      monthDay: json['monthDay'] as int?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'] as int?,
    );
  }

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<int>? weekdays,
    int? monthDay,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      monthDay: monthDay ?? this.monthDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
    );
  }

  String get humanDescription {
    switch (frequency) {
      case RecurrenceFrequency.once:
        return 'مرة واحدة';
      case RecurrenceFrequency.daily:
        return interval > 1 ? 'كل $interval أيام' : 'يومياً';
      case RecurrenceFrequency.everyXHours:
        return 'كل $interval ساعات خلال اليوم';
      case RecurrenceFrequency.specificWeekdays:
        final days = weekdays.map(_dayName).join('، ');
        return 'أيام: $days';
      case RecurrenceFrequency.weekly:
        return 'أسبوعياً';
      case RecurrenceFrequency.biweekly:
        return 'كل أسبوعين';
      case RecurrenceFrequency.monthlyDay:
        return 'شهرياً في يوم $monthDay';
      case RecurrenceFrequency.firstFridayOfMonth:
        return 'أول جمعة من كل شهر';
    }
  }

  static String _dayName(int day) {
    switch (day) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }
}
