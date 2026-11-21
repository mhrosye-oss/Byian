import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../data/circles_api.dart';
import '../data/models/circle.dart';
import '../data/models/circle_type.dart';
import '../data/models/circle_member.dart';
import '../data/models/circle_task.dart';
import '../data/models/circle_dashboard.dart';

export '../data/models/circle.dart';
export '../data/models/circle_type.dart';
export '../data/models/circle_member.dart';
export '../data/models/circle_task.dart';
export '../data/models/circle_dashboard.dart';
export '../data/circles_api.dart';

/// Circles API provider
final circlesApiProvider = Provider<CirclesApi>((ref) {
  return CirclesApi();
});

/// Current user ID provider
final currentUserIdProvider = FutureProvider<int?>((ref) async {
  return AuthService.getUserId();
});

/// Circle Types provider (dynamically fetched from API)
final circleTypesProvider = FutureProvider<List<CircleType>>((ref) async {
  final api = ref.watch(circlesApiProvider);
  return api.fetchCircleTypes();
});

/// My Circles provider
final myCirclesProvider =
    StateNotifierProvider<MyCirclesNotifier, AsyncValue<List<Circle>>>((ref) {
  final api = ref.watch(circlesApiProvider);
  return MyCirclesNotifier(api);
});

class MyCirclesNotifier extends StateNotifier<AsyncValue<List<Circle>>> {
  final CirclesApi _api;

  MyCirclesNotifier(this._api) : super(const AsyncValue.loading()) {
    loadCircles();
  }

  Future<void> loadCircles() async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchMyCircles();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadCircles();

  void addCircle(Circle circle) {
    state.whenData((list) {
      state = AsyncValue.data([circle, ...list]);
    });
  }

  void removeCircle(String uuid) {
    state.whenData((list) {
      state = AsyncValue.data(list.where((c) => c.uuid != uuid).toList());
    });
  }
}

/// Owned Circles provider (filtered where isOwner == true)
final ownedCirclesProvider = Provider<List<Circle>>((ref) {
  final myCirclesState = ref.watch(myCirclesProvider);
  return myCirclesState.maybeWhen(
    data: (circles) => circles.where((c) => c.isOwner).toList(),
    orElse: () => [],
  );
});

/// True if current user is owner of at least one circle
final hasOwnedCirclesProvider = Provider<bool>((ref) {
  final owned = ref.watch(ownedCirclesProvider);
  return owned.isNotEmpty;
});

/// My invitations provider
final myInvitationsProvider = StateNotifierProvider<MyInvitationsNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final api = ref.watch(circlesApiProvider);
  return MyInvitationsNotifier(api);
});

class MyInvitationsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CirclesApi _api;

  MyInvitationsNotifier(this._api) : super(const AsyncValue.loading()) {
    loadInvitations();
  }

  Future<void> loadInvitations() async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchMyInvitations();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadInvitations();

  Future<bool> acceptInvitation(String invitationUuid) async {
    await _api.acceptInvitation(invitationUuid);
    state.whenData((items) {
      state = AsyncValue.data(
        items
            .where((item) => (item['uuid'] ?? item['id']) != invitationUuid)
            .toList(),
      );
    });
    return true;
  }

  Future<bool> declineInvitation(String invitationUuid) async {
    await _api.declineInvitation(invitationUuid);
    state.whenData((items) {
      state = AsyncValue.data(
        items
            .where((item) => (item['uuid'] ?? item['id']) != invitationUuid)
            .toList(),
      );
    });
    return true;
  }
}

/// My Tasks provider
final myTasksProvider =
    StateNotifierProvider<MyTasksNotifier, AsyncValue<List<CircleTask>>>((ref) {
  final api = ref.watch(circlesApiProvider);
  return MyTasksNotifier(api);
});

class MyTasksNotifier extends StateNotifier<AsyncValue<List<CircleTask>>> {
  final CirclesApi _api;

  MyTasksNotifier(this._api) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchMyTasks();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadTasks();

  Future<bool> completeTask(
    String taskUuid, {
    String? evidenceUrl,
  }) async {
    final success = await _api.completeTask(taskUuid, evidenceUrl: evidenceUrl);
    if (success) {
      state.whenData((tasks) {
        state = AsyncValue.data(
          tasks.map((t) {
            if (t.uuid == taskUuid) {
              return t.copyWith(
                status: TaskStatus.completed,
                completedAt: DateTime.now(),
              );
            }
            return t;
          }).toList(),
        );
      });
    }
    return success;
  }

  Future<Map<String, dynamic>> incrementTask(
    String taskUuid, {
    int amount = 1,
  }) async {
    final result = await _api.incrementTask(taskUuid, amount: amount);
    state.whenData((tasks) {
      state = AsyncValue.data(tasks.map((task) {
        if (task.uuid != taskUuid) return task;
        final progress = task.progressValue + amount;
        final completed =
            task.targetValue != null && progress >= task.targetValue!;
        return task.copyWith(
          progressValue: progress,
          status: completed ? TaskStatus.completed : TaskStatus.inProgress,
          completedAt: completed ? DateTime.now() : task.completedAt,
        );
      }).toList());
    });
    return result;
  }
}

/// Circle Dashboard provider family
final circleDashboardProvider = StateNotifierProvider.family<
    CircleDashboardNotifier,
    AsyncValue<CircleDashboardData>,
    String>((ref, circleUuid) {
  final api = ref.watch(circlesApiProvider);
  return CircleDashboardNotifier(api, circleUuid);
});

class CircleDashboardNotifier
    extends StateNotifier<AsyncValue<CircleDashboardData>> {
  final CirclesApi _api;
  final String circleUuid;

  CircleDashboardNotifier(this._api, this.circleUuid)
      : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard({Circle? fallbackCircle}) async {
    try {
      state = const AsyncValue.loading();
      final data = await _api.fetchCircleDashboard(
        circleUuid,
        fallbackCircle: fallbackCircle,
      );

      // Also try fetching full tasks and members to guarantee complete tabs
      List<CircleTask> tasks = data.tasks;
      List<CircleMember> members = data.members;

      if (tasks.isEmpty) {
        try {
          tasks = await _api.fetchCircleTasks(circleUuid);
        } catch (_) {}
      }

      if (members.isEmpty) {
        try {
          members = await _api.fetchCircleMembers(circleUuid);
        } catch (_) {}
      }

      state = AsyncValue.data(data.copyWith(
        tasks: tasks,
        members: members,
        tasksCount:
            tasks.length > data.tasksCount ? tasks.length : data.tasksCount,
        membersCount: members.length > data.membersCount
            ? members.length
            : data.membersCount,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<bool> completeTask(
    String taskUuid, {
    String? evidenceUrl,
  }) async {
    final success = await _api.completeTask(taskUuid, evidenceUrl: evidenceUrl);
    if (success) {
      state.whenData((dashboard) {
        final updatedTasks = dashboard.tasks.map((t) {
          if (t.uuid == taskUuid) {
            return t.copyWith(
              status: TaskStatus.completed,
              completedAt: DateTime.now(),
            );
          }
          return t;
        }).toList();

        final completedCount = updatedTasks.where((t) => t.isCompleted).length;

        state = AsyncValue.data(
          dashboard.copyWith(
            tasks: updatedTasks,
            completedTasksCount: completedCount,
          ),
        );
      });
    }
    return success;
  }

  Future<Map<String, dynamic>> incrementTask(
    String taskUuid, {
    int amount = 1,
  }) async {
    final result = await _api.incrementTask(taskUuid, amount: amount);
    state.whenData((value) {
      final updatedTasks = value.tasks.map((task) {
        if (task.uuid != taskUuid) return task;
        final progress = task.progressValue + amount;
        final completed =
            task.targetValue != null && progress >= task.targetValue!;
        return task.copyWith(
          progressValue: progress,
          status: completed ? TaskStatus.completed : TaskStatus.inProgress,
          completedAt: completed ? DateTime.now() : task.completedAt,
        );
      }).toList();
      state = AsyncValue.data(value.copyWith(tasks: updatedTasks));
    });
    return result;
  }

  Future<bool> leaveCircle() async {
    return _api.leaveCircle(circleUuid);
  }
}
