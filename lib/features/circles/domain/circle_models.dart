class CircleType {
  const CircleType(
      {required this.id,
      required this.key,
      required this.name,
      this.description});

  final int id;
  final String key;
  final String name;
  final String? description;

  factory CircleType.fromJson(Map<String, dynamic> json) => CircleType(
        id: _asInt(json['id']),
        key: '${json['key'] ?? json['slug'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: json['description']?.toString(),
      );
}

class Circle {
  const Circle({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    this.status,
    this.privacyMode,
    this.type,
    this.membersCount = 0,
    this.myRole,
    this.myRelationship,
    this.createdAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String? description;
  final String? status;
  final String? privacyMode;
  final CircleType? type;
  final int membersCount;
  final String? myRole;
  final String? myRelationship;
  final DateTime? createdAt;

  factory Circle.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    return Circle(
      id: _asInt(json['id']),
      uuid: '${json['uuid'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      privacyMode: (json['privacy_mode'] ?? json['privacyMode'])?.toString(),
      type: rawType is Map
          ? CircleType.fromJson(Map<String, dynamic>.from(rawType))
          : null,
      membersCount: _asInt(json['members_count'] ?? json['membersCount']),
      myRole: (json['my_role'] ?? json['myRole'])?.toString(),
      myRelationship:
          (json['my_relationship'] ?? json['myRelationship'])?.toString(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}

class CircleMember {
  const CircleMember({
    required this.uuid,
    this.userId,
    this.name,
    this.role,
    this.relationship,
    this.status,
    this.joinedAt,
  });

  final String uuid;
  final int? userId;
  final String? name;
  final String? role;
  final String? relationship;
  final String? status;
  final DateTime? joinedAt;

  factory CircleMember.fromJson(Map<String, dynamic> json) => CircleMember(
        uuid: '${json['uuid'] ?? ''}',
        userId: json['user_id'] == null ? null : _asInt(json['user_id']),
        name: (json['name'] ??
                (json['user'] is Map ? json['user']['name'] : null))
            ?.toString(),
        role: json['role']?.toString(),
        relationship: json['relationship']?.toString(),
        status: json['status']?.toString(),
        joinedAt: DateTime.tryParse('${json['joined_at'] ?? ''}'),
      );
}

class CircleWhisper {
  const CircleWhisper({
    required this.uuid,
    this.senderId,
    this.templateKey,
    this.messageText,
    this.createdAt,
  });

  final String uuid;
  final int? senderId;
  final String? templateKey;
  final String? messageText;
  final DateTime? createdAt;

  factory CircleWhisper.fromJson(Map<String, dynamic> json) => CircleWhisper(
        uuid: '${json['uuid'] ?? ''}',
        senderId: json['sender_id'] == null ? null : _asInt(json['sender_id']),
        templateKey: json['template_key']?.toString(),
        messageText: json['message_text']?.toString(),
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      );
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
