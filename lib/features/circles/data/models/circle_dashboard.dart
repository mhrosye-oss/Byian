import 'circle.dart';
import 'circle_member.dart';
import 'circle_task.dart';

class CircleDashboardData {
  final Circle circle;
  final List<CircleMember> members;
  final List<CircleTask> tasks;
  final List<Map<String, dynamic>> whispers;
  final List<Map<String, dynamic>> recentActivities;
  final int membersCount;
  final int tasksCount;
  final int completedTasksCount;
  final int whispersCount;

  const CircleDashboardData({
    required this.circle,
    this.members = const [],
    this.tasks = const [],
    this.whispers = const [],
    this.recentActivities = const [],
    required this.membersCount,
    required this.tasksCount,
    required this.completedTasksCount,
    required this.whispersCount,
  });

  bool get canLeave => !circle.isOwner;

  factory CircleDashboardData.fromJson(
    Map<String, dynamic> json, {
    Circle? fallbackCircle,
    int? currentUserId,
  }) {
    // 1. Circle data
    Circle parsedCircle;
    if (json['circle'] is Map<String, dynamic>) {
      parsedCircle = Circle.fromJson(json['circle'] as Map<String, dynamic>);
    } else if (fallbackCircle != null) {
      parsedCircle = fallbackCircle;
    } else {
      parsedCircle = Circle.fromJson(json);
    }

    // 2. Members list
    final membersList = <CircleMember>[];
    if (json['members'] is List) {
      for (final m in json['members']) {
        if (m is Map<String, dynamic>) {
          membersList.add(CircleMember.fromJson(m));
        }
      }
    }

    // 3. Tasks list
    final tasksList = <CircleTask>[];
    if (json['tasks'] is List) {
      for (final t in json['tasks']) {
        if (t is Map<String, dynamic>) {
          tasksList.add(
            CircleTask.fromJson(t, currentUserId: currentUserId),
          );
        }
      }
    }

    // 4. Whispers list
    final whispersList = <Map<String, dynamic>>[];
    if (json['whispers'] is List) {
      for (final w in json['whispers']) {
        if (w is Map<String, dynamic>) {
          whispersList.add(w);
        }
      }
    } else if (json['dashboard'] is Map &&
        json['dashboard']['latest_whisper'] is Map) {
      whispersList.add(Map<String, dynamic>.from(
          json['dashboard']['latest_whisper'] as Map));
    }

    // 5. Recent activities
    final activitiesList = <Map<String, dynamic>>[];
    if (json['activities'] is List) {
      for (final a in json['activities']) {
        if (a is Map<String, dynamic>) {
          activitiesList.add(a);
        }
      }
    } else if (json['dashboard'] is Map &&
        json['dashboard']['recent_activities'] is List) {
      for (final a in json['dashboard']['recent_activities']) {
        if (a is Map) {
          activitiesList.add(Map<String, dynamic>.from(a));
        }
      }
    }

    // 6. Counts
    final mCount = json['members_count'] is int
        ? json['members_count'] as int
        : (membersList.isNotEmpty
            ? membersList.length
            : parsedCircle.membersCount);

    final tCount = json['tasks_count'] is int
        ? json['tasks_count'] as int
        : tasksList.length;

    final compCount = json['completed_tasks_count'] is int
        ? json['completed_tasks_count'] as int
        : tasksList.where((t) => t.isCompleted).length;

    final wCount = json['whispers_count'] is int
        ? json['whispers_count'] as int
        : whispersList.length;

    return CircleDashboardData(
      circle: parsedCircle,
      members: membersList,
      tasks: tasksList,
      whispers: whispersList,
      recentActivities: activitiesList,
      membersCount: mCount,
      tasksCount: tCount,
      completedTasksCount: compCount,
      whispersCount: wCount,
    );
  }

  CircleDashboardData copyWith({
    Circle? circle,
    List<CircleMember>? members,
    List<CircleTask>? tasks,
    List<Map<String, dynamic>>? whispers,
    List<Map<String, dynamic>>? recentActivities,
    int? membersCount,
    int? tasksCount,
    int? completedTasksCount,
    int? whispersCount,
  }) {
    return CircleDashboardData(
      circle: circle ?? this.circle,
      members: members ?? this.members,
      tasks: tasks ?? this.tasks,
      whispers: whispers ?? this.whispers,
      recentActivities: recentActivities ?? this.recentActivities,
      membersCount: membersCount ?? this.membersCount,
      tasksCount: tasksCount ?? this.tasksCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      whispersCount: whispersCount ?? this.whispersCount,
    );
  }
}
