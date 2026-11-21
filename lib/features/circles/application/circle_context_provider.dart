import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/auth_service.dart';
import '../data/circle_api_service.dart';
import '../domain/circle_models.dart';

final circleApiServiceProvider = Provider<CircleApiService>((ref) {
  return CircleApiService();
});

final circleCurrentUserIdProvider = FutureProvider<int?>((ref) {
  return AuthService.getUserId();
});

/// حالة قائمة دوائر المستخدم
final myCirclesProvider =
    StateNotifierProvider<MyCirclesNotifier, AsyncValue<List<CircleModel>>>(
        (ref) {
  final api = ref.watch(circleApiServiceProvider);
  return MyCirclesNotifier(api);
});

class MyCirclesNotifier extends StateNotifier<AsyncValue<List<CircleModel>>> {
  MyCirclesNotifier(this._api) : super(const AsyncValue.loading()) {
    loadCircles();
  }

  final CircleApiService _api;

  Future<void> loadCircles() async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchMyCircles();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() => loadCircles();
}

/// سياق الدائرة النشطة المفتوحة حالياً
final activeCircleContextProvider =
    StateNotifierProvider<ActiveCircleContextNotifier, ActiveCircleContext?>(
        (ref) {
  final api = ref.watch(circleApiServiceProvider);
  return ActiveCircleContextNotifier(api, ref);
});

class ActiveCircleContextNotifier extends StateNotifier<ActiveCircleContext?> {
  ActiveCircleContextNotifier(this._api, this._ref) : super(null);

  final CircleApiService _api;
  final Ref _ref;

  Future<void> selectCircle(String circleUuid) async {
    try {
      final context = await _api.fetchCircleDashboard(circleUuid);
      state = context;
      _ref.read(circleActivitiesProvider.notifier).loadActivities(circleUuid);
      _ref.read(circleWhispersProvider.notifier).loadWhispers(circleUuid);
      await _ref.read(circleMembersProvider.notifier).loadMembers(circleUuid);
    } catch (_) {
      rethrow;
    }
  }

  void clearContext() {
    state = null;
  }
}

/// أنشطة الدائرة النشطة
final circleActivitiesProvider = StateNotifierProvider<CircleActivitiesNotifier,
    AsyncValue<List<CircleActivityModel>>>((ref) {
  final api = ref.watch(circleApiServiceProvider);
  return CircleActivitiesNotifier(api);
});

class CircleActivitiesNotifier
    extends StateNotifier<AsyncValue<List<CircleActivityModel>>> {
  CircleActivitiesNotifier(this._api) : super(const AsyncValue.data([]));

  final CircleApiService _api;

  Future<void> loadActivities(String circleUuid) async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchActivities(circleUuid);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> incrementCounter(String activityUuid, {int step = 1}) async {
    final idempotencyKey = const Uuid().v4();
    try {
      final res = await _api.incrementActivity(activityUuid,
          step: step, idempotencyKey: idempotencyKey);
      final newCurrent = res['current'] as int? ?? 0;

      // تحديث محلي سريع
      state = state.whenData((activities) {
        return activities.map((a) {
          if (a.uuid == activityUuid) {
            return a.copyWith(currentCount: newCurrent);
          }
          return a;
        }).toList();
      });
    } catch (_) {
      rethrow;
    }
  }
}

/// همسات الدائرة النشطة
final circleWhispersProvider = StateNotifierProvider<CircleWhispersNotifier,
    AsyncValue<List<CircleWhisperModel>>>((ref) {
  final api = ref.watch(circleApiServiceProvider);
  return CircleWhispersNotifier(api);
});

class CircleWhispersNotifier
    extends StateNotifier<AsyncValue<List<CircleWhisperModel>>> {
  CircleWhispersNotifier(this._api) : super(const AsyncValue.data([]));

  final CircleApiService _api;

  Future<void> loadWhispers(String circleUuid) async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchWhispers(circleUuid);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> respond(String whisperUuid, String responseKey) async {
    try {
      await _api.respondWhisper(whisperUuid, responseKey);
      state = state.whenData((whispers) {
        return whispers.map((w) {
          if (w.uuid == whisperUuid) {
            return CircleWhisperModel(
              uuid: w.uuid,
              templateKey: w.templateKey,
              content: w.content,
              hasResponded: true,
              createdAt: w.createdAt,
              allowedResponses: w.allowedResponses,
            );
          }
          return w;
        }).toList();
      });
    } catch (_) {
      rethrow;
    }
  }
}

/// أعضاء الدائرة النشطة
final circleMembersProvider = StateNotifierProvider<CircleMembersNotifier,
    AsyncValue<List<CircleMemberModel>>>((ref) {
  final api = ref.watch(circleApiServiceProvider);
  return CircleMembersNotifier(api);
});

class CircleMembersNotifier
    extends StateNotifier<AsyncValue<List<CircleMemberModel>>> {
  CircleMembersNotifier(this._api) : super(const AsyncValue.data([]));

  final CircleApiService _api;

  Future<void> loadMembers(String circleUuid) async {
    try {
      state = const AsyncValue.loading();
      final list = await _api.fetchMembers(circleUuid);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// إدارة وضع "باب السكينة" الهادئ محلياً بالكامل (No API, No Tracking, SharedPreferences only)
final quietDoorProvider = StateNotifierProvider<QuietDoorNotifier, bool>((ref) {
  return QuietDoorNotifier();
});

class QuietDoorNotifier extends StateNotifier<bool> {
  QuietDoorNotifier() : super(false) {
    _loadState();
  }

  static const String _key = 'itqan_quiet_door_active';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, next);
  }
}
