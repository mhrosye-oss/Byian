enum SuggestionType {
  timeConflict, // تزامن موعدين بفارق زمني ضيق جداً
  densityWarning, // تجاوز الحد اليومي المقترح (8 تذكيرات)
  quietHoursInterference, // تداخل موعد مع فترة الهدوء
  betterDistribution, // اقتراح توزيع هادئ على مدار اليوم
}

/// اقتراح ذكي هادئ يقترح ولا يفرض، ويتطلب موافقة صريحة
class SmartSuggestion {
  final String id;
  final SuggestionType type;
  final String question; // بصيغة سؤال: «هل ترغب في فصل هذين التذكيرين؟»
  final String description; // شرح هادئ
  final String beforeState; // الحالة قبل
  final String afterState; // الحالة بعد في حال الموافقة
  final String? relatedReminderId;
  final String? secondaryReminderId;
  final DateTime? dismissedUntil; // لا يتكرر قبل مرور 3 أيام في حال الرفض

  const SmartSuggestion({
    required this.id,
    required this.type,
    required this.question,
    required this.description,
    required this.beforeState,
    required this.afterState,
    this.relatedReminderId,
    this.secondaryReminderId,
    this.dismissedUntil,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'question': question,
        'description': description,
        'beforeState': beforeState,
        'afterState': afterState,
        'relatedReminderId': relatedReminderId,
        'secondaryReminderId': secondaryReminderId,
        'dismissedUntil': dismissedUntil?.toIso8601String(),
      };

  factory SmartSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartSuggestion(
      id: json['id'] as String,
      type: SuggestionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SuggestionType.timeConflict,
      ),
      question: json['question'] as String,
      description: json['description'] as String,
      beforeState: json['beforeState'] as String,
      afterState: json['afterState'] as String,
      relatedReminderId: json['relatedReminderId'] as String?,
      secondaryReminderId: json['secondaryReminderId'] as String?,
      dismissedUntil: json['dismissedUntil'] != null
          ? DateTime.tryParse(json['dismissedUntil'])
          : null,
    );
  }
}
