import 'package:flutter/material.dart';

enum TaskPriority {
  high,
  normal,
  low;

  static TaskPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      case 'normal':
      default:
        return TaskPriority.normal;
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.normal:
        return 'عادية';
      case TaskPriority.low:
        return 'منخفضة';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Red
      case TaskPriority.normal:
        return const Color(0xFF10B981); // Green
      case TaskPriority.low:
        return const Color(0xFF6B7280); // Grey
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFFEE2E2);
      case TaskPriority.normal:
        return const Color(0xFFD1FAE5);
      case TaskPriority.low:
        return const Color(0xFFF3F4F6);
    }
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed;

  static TaskStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'completed':
      case 'done':
      case 'finished':
        return TaskStatus.completed;
      case 'in_progress':
      case 'inprogress':
      case 'in progress':
      case 'in-progress':
        return TaskStatus.inProgress;
      case 'not_started':
      case 'not started':
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.completed:
        return 'مكتملة';
      case TaskStatus.inProgress:
        return 'جارية';
      case TaskStatus.pending:
        return 'قيد الانتظار';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.completed:
        return const Color(0xFF10B981);
      case TaskStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TaskStatus.pending:
        return const Color(0xFF3B82F6);
    }
  }
}

class CircleTask {
  final String uuid;
  final String title;
  final String? description;
  final String taskType;
  final TaskPriority priority;
  final TaskStatus status;
  final int? assignedToUserId;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String? circleUuid;
  final String? circleName;
  final int progressValue;
  final int? targetValue;
  final String? targetUnit;
  final int? quranStartPage;
  final int? quranEndPage;
  final int? currentValue;
  final bool isSecret;
  final bool hasCurrentUserAssignment;
  final String targetType;
  final bool evidenceRequired;

  const CircleTask({
    required this.uuid,
    required this.title,
    this.description,
    this.taskType = 'general',
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.pending,
    this.assignedToUserId,
    this.dueAt,
    this.completedAt,
    this.circleUuid,
    this.circleName,
    this.progressValue = 0,
    this.targetValue,
    this.targetUnit,
    this.quranStartPage,
    this.quranEndPage,
    this.currentValue,
    this.isSecret = false,
    this.hasCurrentUserAssignment = true,
    this.targetType = 'individual',
    this.evidenceRequired = false,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;

  CircleTask copyWith({
    String? uuid,
    String? title,
    String? description,
    String? taskType,
    TaskPriority? priority,
    TaskStatus? status,
    int? assignedToUserId,
    DateTime? dueAt,
    DateTime? completedAt,
    String? circleUuid,
    String? circleName,
    int? progressValue,
    int? targetValue,
    String? targetUnit,
    int? quranStartPage,
    int? quranEndPage,
    int? currentValue,
    bool? isSecret,
    bool? hasCurrentUserAssignment,
    String? targetType,
    bool? evidenceRequired,
  }) {
    return CircleTask(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
      circleUuid: circleUuid ?? this.circleUuid,
      circleName: circleName ?? this.circleName,
      progressValue: progressValue ?? this.progressValue,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      quranStartPage: quranStartPage ?? this.quranStartPage,
      quranEndPage: quranEndPage ?? this.quranEndPage,
      currentValue: currentValue ?? this.currentValue,
      isSecret: isSecret ?? this.isSecret,
      hasCurrentUserAssignment:
          hasCurrentUserAssignment ?? this.hasCurrentUserAssignment,
      targetType: targetType ?? this.targetType,
      evidenceRequired: evidenceRequired ?? this.evidenceRequired,
    );
  }

  factory CircleTask.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final assignments = json['assignments'];
    Map? assignment;
    var hasCurrentUserAssignment = true;
    if (assignments is List) {
      hasCurrentUserAssignment = assignments.isEmpty || currentUserId == null;
      for (final item in assignments) {
        if (item is! Map) continue;
        final rawUserId = item['user_id'] ?? item['userId'] ?? item['id'];
        final userId = rawUserId is int
            ? rawUserId
            : int.tryParse(rawUserId?.toString() ?? '');
        if (currentUserId != null && userId == currentUserId) {
          assignment = item;
          hasCurrentUserAssignment = true;
          break;
        }
        if (currentUserId == null) assignment ??= item;
      }
      if (currentUserId != null && assignment == null) {
        hasCurrentUserAssignment = false;
      }
    } else if (assignments is Map) {
      final rawUserId =
          assignments['user_id'] ?? assignments['userId'] ?? assignments['id'];
      final userId = rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId?.toString() ?? '');
      if (currentUserId == null) {
        assignment = assignments;
      } else if (userId == currentUserId) {
        assignment = assignments;
      } else {
        hasCurrentUserAssignment = false;
        assignment = null;
      }
    }

    final rawAssigned = json['assigned_to_user_id'] ?? json['assignedToUserId'];
    int? assignedId;
    if (rawAssigned is int) {
      assignedId = rawAssigned;
    } else if (rawAssigned != null) {
      assignedId = int.tryParse(rawAssigned.toString());
    }
    final rawAssignmentUserId =
        assignment?['user_id'] ?? assignment?['userId'] ?? assignment?['id'];
    if (rawAssignmentUserId is int) {
      assignedId = rawAssignmentUserId;
    } else if (rawAssignmentUserId != null) {
      assignedId = int.tryParse(rawAssignmentUserId.toString()) ?? assignedId;
    }

    DateTime? parsedDue;
    if (json['due_at'] != null) {
      parsedDue = DateTime.tryParse(json['due_at'].toString());
    }

    DateTime? parsedCompleted;
    if (json['completed_at'] != null) {
      parsedCompleted = DateTime.tryParse(json['completed_at'].toString());
    }

    final rawStatus = assignment?['status']?.toString() ??
        (assignments is List ? null : json['status']?.toString());
    final rawProgress = assignment?['progress_value'] ??
        (assignments is List
            ? null
            : json['my_progress'] ??
                json['progress_value'] ??
                json['progress']);
    int prog = 0;
    if (rawProgress is int) {
      prog = rawProgress;
    } else if (rawProgress != null) {
      prog = int.tryParse(rawProgress.toString()) ?? 0;
    }

    final rawTarget = json['target_value'] ?? json['targetValue'];
    final rawCurrent = json['current_value'] ?? json['currentValue'];
    final targetValue = rawTarget is int
        ? rawTarget
        : int.tryParse(rawTarget?.toString() ?? '');
    final description = json['description']?.toString();
    final explicitQuranRange = _parseQuranRange(description);
    final rangeFromTitle =
        explicitQuranRange ?? _parseQuranRange(json['title']?.toString());
    final rawQuranStart = json['quran_start_page'] ??
        json['start_page'] ??
        json['from_page'] ??
        rangeFromTitle?.$1;
    final rawQuranEnd = json['quran_end_page'] ??
        json['end_page'] ??
        json['to_page'] ??
        rangeFromTitle?.$2;
    final quranStartPage = _asPositiveInt(rawQuranStart);
    final quranEndPage = _asPositiveInt(rawQuranEnd);
    final currentValue = rawCurrent is int
        ? rawCurrent
        : int.tryParse(rawCurrent?.toString() ?? '');
    final rawSecret = json['is_secret']?.toString().toLowerCase();
    final rawEvidenceRequired =
        json['evidence_required']?.toString().toLowerCase();
    final rawCircle = json['circle'];
    final circleUuid = json['circle_uuid'] ??
        json['circleUuid'] ??
        (rawCircle is Map ? rawCircle['uuid'] : null);

    return CircleTask(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: description,
      taskType: json['task_type']?.toString() ??
          json['type']?.toString() ??
          'general',
      priority: TaskPriority.fromString(json['priority']?.toString()),
      status: TaskStatus.fromString(rawStatus),
      assignedToUserId: assignedId,
      dueAt: parsedDue,
      completedAt: parsedCompleted,
      circleUuid: circleUuid?.toString(),
      circleName: json['circle_name']?.toString() ??
          (rawCircle is Map ? rawCircle['name']?.toString() : null),
      progressValue: prog,
      targetValue: targetValue,
      targetUnit: json['target_unit']?.toString() ?? json['unit']?.toString(),
      quranStartPage: quranStartPage,
      quranEndPage: quranEndPage,
      currentValue: currentValue,
      isSecret: rawSecret == 'true' || rawSecret == '1',
      hasCurrentUserAssignment: hasCurrentUserAssignment,
      targetType: json['target_type']?.toString().toLowerCase() ?? 'individual',
      evidenceRequired:
          rawEvidenceRequired == 'true' || rawEvidenceRequired == '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'title': title,
        if (description != null) 'description': description,
        'task_type': taskType,
        'priority': priority.name,
        'status': status.name,
        if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
        if (dueAt != null) 'due_at': dueAt?.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt?.toIso8601String(),
        if (circleUuid != null) 'circle_uuid': circleUuid,
        if (circleName != null) 'circle_name': circleName,
        'progress_value': progressValue,
        if (targetValue != null) 'target_value': targetValue,
        if (targetUnit != null) 'target_unit': targetUnit,
        if (quranStartPage != null) 'quran_start_page': quranStartPage,
        if (quranEndPage != null) 'quran_end_page': quranEndPage,
        if (currentValue != null) 'current_value': currentValue,
        if (isSecret) 'is_secret': true,
        'target_type': targetType,
        'evidence_required': evidenceRequired,
      };
}

int? _asPositiveInt(dynamic value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}

(int, int)? _parseQuranRange(String? text) {
  if (text == null) return null;
  final match = RegExp(
    r'(?:الصفحات?|صفحة)\s*(\d+)\s*(?:إلى|الى|[-–])\s*(\d+)',
  ).firstMatch(text);
  if (match == null) return null;
  final start = int.tryParse(match.group(1)!);
  final end = int.tryParse(match.group(2)!);
  if (start == null || end == null || start < 1 || end < start || end > 604) {
    return null;
  }
  return (start, end);
}
