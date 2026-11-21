/// كيان البرنامج في خدمة «فَذَكِّر»
class FazakkirProgram {
  final String id;
  final String name;
  final String description;
  final String? iconName;
  final bool isPaused;
  final DateTime createdAt;
  final List<String> reminderIds; // معرفات التذكيرات المرتبطة بهذا البرنامج

  const FazakkirProgram({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    this.isPaused = false,
    required this.createdAt,
    this.reminderIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconName': iconName,
        'isPaused': isPaused,
        'createdAt': createdAt.toIso8601String(),
        'reminderIds': reminderIds,
      };

  factory FazakkirProgram.fromJson(Map<String, dynamic> json) {
    return FazakkirProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['iconName'] as String?,
      isPaused: json['isPaused'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      reminderIds: (json['reminderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  FazakkirProgram copyWith({
    String? name,
    String? description,
    String? iconName,
    bool? isPaused,
    List<String>? reminderIds,
  }) {
    return FazakkirProgram(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt,
      reminderIds: reminderIds ?? this.reminderIds,
    );
  }
}
