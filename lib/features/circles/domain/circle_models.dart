class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.totalXp = 0,
    this.totalCoins = 0,
    this.level = 1,
    this.levelTitle,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final int totalXp;
  final int totalCoins;
  final int level;
  final String? levelTitle;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: _int(json['id']),
        name: _string(json['name']),
        email: _string(json['email']),
        phone: json['phone']?.toString(),
        totalXp: _int(json['total_xp'] ?? json['totalXp']),
        totalCoins: _int(json['total_coins'] ?? json['totalCoins']),
        level: _int(json['level'], fallback: 1),
        levelTitle: (json['level_title'] ?? json['levelTitle'])?.toString(),
      );
}

class CircleType {
  const CircleType({
    required this.id,
    required this.key,
    required this.name,
    this.description,
  });

  final int id;
  final String key;
  final String name;
  final String? description;

  factory CircleType.fromJson(Map<String, dynamic> json) => CircleType(
        id: _int(json['id']),
        key: _string(json['key'] ?? json['slug']),
        name: _string(json['name']),
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
    this.isOwnerFromApi = false,
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
  final bool isOwnerFromApi;
  final DateTime? createdAt;

  bool get isOwner =>
      isOwnerFromApi || _isOwnerRole(myRole) || _isOwnerRole(myRelationship);

  factory Circle.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    final membership =
        _map(json['membership'] ?? json['member'] ?? json['my_membership']);
    final rawRole = json['my_role'] ??
        json['myRole'] ??
        json['role'] ??
        membership?['role'];
    final rawRelationship = json['my_relationship'] ??
        json['myRelationship'] ??
        membership?['relationship'];
    final isOwner = _bool(json['is_owner'] ??
        json['isOwner'] ??
        membership?['is_owner'] ??
        membership?['isOwner']);
    return Circle(
      id: _int(json['id']),
      uuid: _string(json['uuid']),
      name: _string(json['name']),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      privacyMode: (json['privacy_mode'] ?? json['privacyMode'])?.toString(),
      type: rawType is Map
          ? CircleType.fromJson(Map<String, dynamic>.from(rawType))
          : null,
      membersCount: _int(json['members_count'] ?? json['membersCount']),
      myRole: rawRole?.toString(),
      myRelationship: rawRelationship?.toString(),
      isOwnerFromApi: isOwner,
      createdAt: _date(json['created_at'] ?? json['createdAt']),
    );
  }
}

bool _isOwnerRole(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized == 'owner' ||
      normalized == 'leader' ||
      normalized == 'قائد';
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
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

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    return CircleMember(
      uuid: _string(json['uuid']),
      userId: json['user_id'] == null ? null : _int(json['user_id']),
      name: (json['name'] ?? user?['name'])?.toString(),
      role: json['role']?.toString(),
      relationship: json['relationship']?.toString(),
      status: json['status']?.toString(),
      joinedAt: _date(json['joined_at']),
    );
  }
}

/// Represents either a cross-circle assignment returned by /me/tasks or a
/// task embedded in a circle response. Assignment status is retained because
/// completion is only permitted for a pending assignment.
class CircleTask {
  const CircleTask({
    required this.uuid,
    required this.title,
    this.description,
    this.priority = 'normal',
    this.status = 'pending',
    this.progressValue = 0,
    this.dueAt,
    this.circleName,
    this.circleUuid,
    this.assignedToUserId,
    this.xpReward,
  });

  final String uuid;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final num progressValue;
  final DateTime? dueAt;
  final String? circleName;
  final String? circleUuid;
  final int? assignedToUserId;
  final int? xpReward;

  bool get isPending => status == 'pending';

  factory CircleTask.fromJson(Map<String, dynamic> json) => CircleTask(
        uuid: _string(json['uuid']),
        title: _string(json['title']),
        description: json['description']?.toString(),
        priority: _string(json['priority'], fallback: 'normal'),
        status: _string(json['status'], fallback: 'pending'),
        progressValue: _num(json['progress_value'] ?? json['progressValue']),
        dueAt: _date(json['due_at'] ?? json['dueAt']),
        circleName: (json['circle_name'] ?? json['circleName'])?.toString(),
        circleUuid: (json['circle_uuid'] ?? json['circleUuid'])?.toString(),
        assignedToUserId: json['assigned_to_user_id'] == null
            ? null
            : _int(json['assigned_to_user_id']),
        xpReward: json['xp_reward'] == null ? null : _int(json['xp_reward']),
      );
}

class CircleActivity {
  const CircleActivity({
    this.description,
    this.actorName,
    this.type,
    this.createdAt,
  });

  final String? description;
  final String? actorName;
  final String? type;
  final DateTime? createdAt;

  factory CircleActivity.fromJson(Map<String, dynamic> json) {
    final actor = _map(json['actor']) ?? _map(json['user']);
    return CircleActivity(
      description:
          (json['description'] ?? json['message'] ?? json['title'])?.toString(),
      actorName: (json['actor_name'] ?? json['user_name'] ?? actor?['name'])
          ?.toString(),
      type: json['type']?.toString(),
      createdAt: _date(json['created_at']),
    );
  }
}

class CircleWhisper {
  const CircleWhisper({
    required this.uuid,
    this.senderId,
    this.templateKey,
    this.messageText,
    this.isAnonymous = false,
    this.createdAt,
  });

  final String uuid;
  final int? senderId;
  final String? templateKey;
  final String? messageText;
  final bool isAnonymous;
  final DateTime? createdAt;

  factory CircleWhisper.fromJson(Map<String, dynamic> json) => CircleWhisper(
        uuid: _string(json['uuid']),
        senderId: json['sender_id'] == null ? null : _int(json['sender_id']),
        templateKey: json['template_key']?.toString(),
        messageText: json['message_text']?.toString(),
        isAnonymous: json['is_anonymous'] == true || json['is_anonymous'] == 1,
        createdAt: _date(json['created_at']),
      );
}

Map<String, dynamic>? _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

String _string(dynamic value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();

int _int(dynamic value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;

num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
