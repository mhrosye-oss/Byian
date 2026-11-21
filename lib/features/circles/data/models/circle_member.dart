class CircleMember {
  final String uuid;
  final int? userId;
  final String displayName;
  final String role; // 'owner', 'admin', 'member'
  final String roleLabel;
  final String? relationshipLabel;
  final bool isManagedProfile;
  final DateTime? joinedAt;

  const CircleMember({
    required this.uuid,
    this.userId,
    required this.displayName,
    required this.role,
    required this.roleLabel,
    this.relationshipLabel,
    this.isManagedProfile = false,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner' || role == 'leader';
  bool get isAdmin => role == 'admin' || isOwner;
  bool get isMember => !isAdmin;

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'] ?? json['app_user_id'] ?? json['id'];
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');
    final rawUser = json['user'] ?? json['app_user'];
    final user = rawUser is Map ? rawUser : const <String, dynamic>{};
    String r = 'member';
    String rLabel = 'عضو';

    if (json['role'] != null) {
      r = json['role'].toString().toLowerCase();
      if (r == 'leader' || r == 'owner') {
        r = 'owner';
        rLabel = 'مالك';
      } else if (r == 'admin') {
        rLabel = 'مشرف';
      } else {
        rLabel = 'عضو';
      }
    } else if (json['roles'] is List) {
      final rolesList = json['roles'] as List;
      if (rolesList.isNotEmpty) {
        final firstRole = rolesList.first;
        if (firstRole is Map) {
          final k = firstRole['key']?.toString().toLowerCase() ?? '';
          if (k == 'leader' || k == 'owner') {
            r = 'owner';
            rLabel = 'مالك';
          } else if (k == 'admin' || k == 'co_leader') {
            r = 'admin';
            rLabel = 'مشرف';
          } else {
            r = 'member';
            rLabel = firstRole['name']?.toString() ?? 'عضو';
          }
        }
      }
    }

    String? rel;
    if (json['relationship'] is Map) {
      rel = json['relationship']['name']?.toString();
    } else if (json['relationship'] is String) {
      rel = json['relationship'] as String;
    }

    DateTime? joined;
    if (json['joined_at'] != null) {
      joined = DateTime.tryParse(json['joined_at'].toString());
    }

    final displayName = [
      json['name'],
      user['name'],
      json['user_name'],
      json['display_name'],
      user['display_name'],
    ]
        .map((value) => value?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => 'مستخدم');

    return CircleMember(
      uuid: json['uuid']?.toString() ?? '',
      userId: userId,
      displayName: displayName,
      role: r,
      roleLabel: rLabel,
      relationshipLabel: rel,
      isManagedProfile: json['is_managed_profile'] == true,
      joinedAt: joined,
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        if (userId != null) 'user_id': userId,
        'display_name': displayName,
        'role': role,
        'role_label': roleLabel,
        if (relationshipLabel != null) 'relationship_label': relationshipLabel,
        'is_managed_profile': isManagedProfile,
        if (joinedAt != null) 'joined_at': joinedAt?.toIso8601String(),
      };
}
