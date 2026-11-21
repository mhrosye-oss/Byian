import 'circle_type.dart';

class Circle {
  final int? id;
  final String uuid;
  final String name;
  final String? description;
  final String status;
  final String privacyMode;
  final CircleType type;
  final int membersCount;
  final String myRole;
  final String? myRelationship;
  final DateTime? createdAt;

  const Circle({
    this.id,
    required this.uuid,
    required this.name,
    this.description,
    this.status = 'active',
    this.privacyMode = 'private',
    required this.type,
    this.membersCount = 1,
    required this.myRole,
    this.myRelationship,
    this.createdAt,
  });

  bool get isOwner =>
      myRole.toLowerCase() == 'owner' || myRole.toLowerCase() == 'leader';

  bool get isAdmin => myRole.toLowerCase() == 'admin' || isOwner;

  bool get isMember => !isAdmin;

  bool get isPrivate => privacyMode.toLowerCase() == 'private';

  String get privacyLabel => isPrivate ? 'خاصة' : 'عامة';

  factory Circle.fromJson(Map<String, dynamic> json) {
    // 1. Parse CircleType
    CircleType parsedType;
    final rawType = json['type'];
    if (rawType is Map<String, dynamic>) {
      parsedType = CircleType.fromJson(rawType);
    } else if (rawType is String && rawType.isNotEmpty) {
      parsedType = CircleType(key: rawType, name: rawType);
    } else {
      final typeKey = json['type_key']?.toString() ?? 'custom';
      final typeName = json['type_name']?.toString() ?? typeKey;
      parsedType = CircleType(key: typeKey, name: typeName);
    }

    // 2. Parse my_role
    String role = 'member';
    if (json['my_role'] != null) {
      role = json['my_role'].toString();
    } else if (json['my_membership'] is Map) {
      final membership = json['my_membership'] as Map;
      final roles = membership['roles'] as List<dynamic>?;
      if (roles != null && roles.isNotEmpty) {
        final firstRole = roles.first;
        if (firstRole is Map && firstRole['key'] != null) {
          final rKey = firstRole['key'].toString();
          role = (rKey == 'leader') ? 'owner' : rKey;
        }
      }
    }

    // 3. Parse relationship
    String? rel;
    if (json['my_relationship'] != null) {
      rel = json['my_relationship'].toString();
    } else if (json['my_membership'] is Map) {
      final membership = json['my_membership'] as Map;
      final relMap = membership['relationship'];
      if (relMap is Map && relMap['name'] != null) {
        rel = relMap['name'].toString();
      }
    }

    // 4. Parse members count
    final rawCount = json['members_count'] ?? json['membersCount'];
    int count = 1;
    if (rawCount is int) {
      count = rawCount;
    } else if (rawCount != null) {
      count = int.tryParse(rawCount.toString()) ?? 1;
    }

    // 5. Parse createdAt
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return Circle(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
      privacyMode: json['privacy_mode']?.toString() ?? 'private',
      type: parsedType,
      membersCount: count,
      myRole: role,
      myRelationship: rel,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'name': name,
        if (description != null) 'description': description,
        'status': status,
        'privacy_mode': privacyMode,
        'type': type.toJson(),
        'members_count': membersCount,
        'my_role': myRole,
        if (myRelationship != null) 'my_relationship': myRelationship,
        if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      };
}

