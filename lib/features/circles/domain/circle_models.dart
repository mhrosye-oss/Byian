import '../data/models/circle.dart';
import '../data/models/circle_type.dart';

export '../data/models/circle.dart';
export '../data/models/circle_type.dart';
export '../data/models/circle_member.dart';
export '../data/models/circle_task.dart';
export '../data/models/circle_dashboard.dart';

class RelationshipInfo {
  final String key;
  final String name;

  const RelationshipInfo({required this.key, required this.name});

  factory RelationshipInfo.fromJson(Map<String, dynamic> json) =>
      RelationshipInfo(
        key: json['key']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'key': key, 'name': name};
}

class CircleTypeInfo {
  final int? id;
  final String key;
  final String name;
  final String description;
  final List<RelationshipInfo> relationships;

  const CircleTypeInfo({
    this.id,
    required this.key,
    required this.name,
    this.description = '',
    this.relationships = const [],
  });

  factory CircleTypeInfo.fromJson(Map<String, dynamic> json) {
    final relList = json['relationships'] as List<dynamic>? ?? [];
    return CircleTypeInfo(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      relationships: relList
          .map((r) =>
              RelationshipInfo.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'key': key,
        'name': name,
        'description': description,
        'relationships': relationships.map((r) => r.toJson()).toList(),
      };
}

class CircleModel {
  final String uuid;
  final String name;
  final String description;
  final CircleTypeInfo type;
  final String status;
  final String privacyMode;
  final int membersCount;
  final int activeActivitiesCount;
  final String? myRoleKey;
  final String? myRoleName;
  final String? myRelationshipName;

  const CircleModel({
    required this.uuid,
    required this.name,
    this.description = '',
    required this.type,
    this.status = 'active',
    this.privacyMode = 'private',
    this.membersCount = 1,
    this.activeActivitiesCount = 0,
    this.myRoleKey,
    this.myRoleName,
    this.myRelationshipName,
  });

  bool get isFamily => type.key == 'family';
  bool get isClassroom => type.key == 'classroom';
  String get typeKey => type.key;
  String get typeName => type.name;

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    final typeMap = json['type'] as Map<String, dynamic>? ?? {};
    final myMem = json['my_membership'] as Map<String, dynamic>?;
    final rolesList = myMem?['roles'] as List<dynamic>? ?? [];
    final firstRole = rolesList.isNotEmpty
        ? Map<String, dynamic>.from(rolesList.first as Map)
        : null;
    final relMap = myMem?['relationship'] as Map<String, dynamic>?;

    final typeInfo = CircleTypeInfo(
      id: typeMap['id'] is int ? typeMap['id'] as int : null,
      key: typeMap['key']?.toString() ?? 'family',
      name: typeMap['name']?.toString() ?? 'دائرة',
      description: typeMap['description']?.toString() ?? '',
    );

    return CircleModel(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: typeInfo,
      status: json['status']?.toString() ?? 'active',
      privacyMode: json['privacy_mode']?.toString() ?? 'private',
      membersCount: json['members_count'] as int? ?? 1,
      activeActivitiesCount: json['active_activities_count'] as int? ?? 0,
      myRoleKey: firstRole?['key']?.toString() ?? json['my_role']?.toString(),
      myRoleName: firstRole?['name']?.toString(),
      myRelationshipName: relMap?['name']?.toString(),
    );
  }

  Circle toCircle() {
    return Circle(
      uuid: uuid,
      name: name,
      description: description,
      status: status,
      privacyMode: privacyMode,
      type: CircleType(
          id: type.id,
          key: type.key,
          name: type.name,
          description: type.description),
      membersCount: membersCount,
      myRole: myRoleKey ?? 'member',
      myRelationship: myRelationshipName,
    );
  }
}

class ActiveCircleContext {
  final CircleModel circle;
  final List<String> permissions;
  final List<String> enabledModules;
  final String dashboardKey;

  const ActiveCircleContext({
    required this.circle,
    this.permissions = const [],
    this.enabledModules = const [],
    this.dashboardKey = 'member',
  });

  bool hasPermission(String permission) => permissions.contains(permission);
  bool isModuleEnabled(String module) => enabledModules.contains(module);
  bool can(String permission) => hasPermission(permission);
  bool hasModule(String module) => isModuleEnabled(module);
}

class CircleMemberModel {
  final String uuid;
  final int? userId;
  final String displayName;
  final bool isManagedProfile;
  final String ageGroup;
  final List<String> roleNames;
  final String? relationshipLabel;
  final String joinedAt;

  const CircleMemberModel({
    required this.uuid,
    this.userId,
    required this.displayName,
    this.isManagedProfile = false,
    this.ageGroup = 'adult',
    this.roleNames = const [],
    this.relationshipLabel,
    this.joinedAt = '',
  });

  String get primaryRole => roleNames.isNotEmpty ? roleNames.first : 'عضو';
  String? get relationshipName => relationshipLabel;

  factory CircleMemberModel.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'] ?? json['app_user_id'] ?? json['id'];
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');
    final user = _asJsonMap(json['user']) ?? _asJsonMap(json['app_user']);
    final rolesList = json['roles'] as List<dynamic>? ?? [];
    final names = <String>[];
    for (final r in rolesList) {
      if (r is Map && r['name'] != null) {
        names.add(r['name'].toString());
      } else if (r is String) {
        names.add(r);
      }
    }
    if (names.isEmpty && json['role'] != null) {
      switch (json['role'].toString().toLowerCase()) {
        case 'owner':
        case 'leader':
          names.add('مالك');
        case 'admin':
          names.add('مشرف');
        case 'member':
          names.add('عضو');
        default:
          names.add(json['role'].toString());
      }
    }

    String? rel;
    if (json['relationship'] is Map) {
      rel = json['relationship']['name']?.toString();
    } else if (json['relationship'] is String) {
      rel = json['relationship'] as String;
    }

    final name = _firstNonEmpty([
      json['name'],
      user?['name'],
      json['user_name'],
      json['display_name'],
      user?['display_name'],
    ]);
    return CircleMemberModel(
      uuid: json['uuid']?.toString() ?? '',
      userId: userId,
      displayName: name ?? 'مستخدم',
      isManagedProfile: json['is_managed_profile'] == true,
      ageGroup: json['age_group']?.toString() ?? 'adult',
      roleNames: names,
      relationshipLabel: rel,
      joinedAt: json['joined_at']?.toString() ?? '',
    );
  }
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

class CircleActivityModel {
  final String uuid;
  final String title;
  final String status;
  final String typeKey;
  final String typeName;
  final String tabType;
  final String? message;
  final String? userName;
  final String? createdAt;
  final int currentCount;
  final int targetCount;

  const CircleActivityModel({
    required this.uuid,
    required this.title,
    this.status = 'active',
    this.typeKey = 'general',
    this.typeName = 'نشاط',
    this.tabType = 'activity',
    this.message,
    this.userName,
    this.createdAt,
    this.currentCount = 0,
    this.targetCount = 0,
  });

  double get progress =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  factory CircleActivityModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    final typeMap = rawType is Map
        ? Map<String, dynamic>.from(rawType)
        : const <String, dynamic>{};
    final counterMap = json['counter'] is Map
        ? Map<String, dynamic>.from(json['counter'] as Map)
        : const <String, dynamic>{};
    final typeKey =
        (json['tab_type'] ?? typeMap['key'] ?? rawType ?? 'general').toString();
    const typeNames = {
      'dua': 'الدعاء',
      'question': 'السؤال',
      'study': 'الدراسة',
      'task': 'المهام',
      'whisper': 'الهمسات',
      'member': 'الأعضاء',
      'khatmah': 'الختمات',
      'invitation': 'الدعوات',
    };

    return CircleActivityModel(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      typeKey: typeKey,
      typeName: typeMap['name']?.toString() ?? typeNames[typeKey] ?? 'نشاط',
      tabType: (json['tab_type'] ?? typeKey).toString(),
      message: json['message']?.toString(),
      userName: json['user_name']?.toString(),
      createdAt: json['created_at']?.toString(),
      currentCount: _circleActivityInt(
            counterMap['current'] ?? json['current_count'],
          ) ??
          0,
      targetCount:
          _circleActivityInt(counterMap['target'] ?? json['target_count']) ?? 0,
    );
  }

  CircleActivityModel copyWith({int? currentCount}) => CircleActivityModel(
        uuid: uuid,
        title: title,
        status: status,
        typeKey: typeKey,
        typeName: typeName,
        tabType: tabType,
        message: message,
        userName: userName,
        createdAt: createdAt,
        currentCount: currentCount ?? this.currentCount,
        targetCount: targetCount,
      );
}

int? _circleActivityInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

class WhisperResponseOption {
  final String key;
  final String label;

  const WhisperResponseOption({required this.key, required this.label});
}

class CircleWhisperModel {
  final String uuid;
  final String templateKey;
  final String content;
  final String status;
  final String createdAt;
  final bool hasResponded;
  final List<WhisperResponseOption> allowedResponses;

  const CircleWhisperModel({
    required this.uuid,
    required this.templateKey,
    required this.content,
    this.status = 'active',
    this.createdAt = '',
    this.hasResponded = false,
    this.allowedResponses = const [],
  });

  factory CircleWhisperModel.fromJson(Map<String, dynamic> json) {
    final respList = json['allowed_responses'] as List<dynamic>? ?? [];
    return CircleWhisperModel(
      uuid: json['uuid']?.toString() ?? '',
      templateKey: json['template_key']?.toString() ?? '',
      content:
          json['message_text']?.toString() ?? json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at']?.toString() ?? '',
      hasResponded: json['has_responded'] == true,
      allowedResponses: respList.map((r) {
        if (r is Map) {
          return WhisperResponseOption(
            key: r['key']?.toString() ?? '',
            label: r['label']?.toString() ?? '',
          );
        }
        return WhisperResponseOption(key: r.toString(), label: r.toString());
      }).toList(),
    );
  }
}
