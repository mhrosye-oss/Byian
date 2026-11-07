import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/services/auth_service.dart';

final itqanJourneyRepositoryProvider =
    Provider<ItqanJourneyRepository>((ref) => ItqanJourneyRepository());
final itqanJourneyProvider =
    StateNotifierProvider<ItqanJourneyNotifier, ItqanJourneyState>(
  (ref) => ItqanJourneyNotifier(ref.read(itqanJourneyRepositoryProvider)),
);

class ItqanJourneyState {
  const ItqanJourneyState({
    this.loading = false,
    this.error,
    this.profile,
    this.tasks,
    this.journey,
    this.streak,
    this.achievements,
    this.leaderboard,
    this.lastActivity,
  });

  final bool loading;
  final String? error;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? tasks;
  final Map<String, dynamic>? journey;
  final Map<String, dynamic>? streak;
  final Map<String, dynamic>? achievements;
  final Map<String, dynamic>? leaderboard;
  final Map<String, dynamic>? lastActivity;

  ItqanJourneyState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? tasks,
    Map<String, dynamic>? journey,
    Map<String, dynamic>? streak,
    Map<String, dynamic>? achievements,
    Map<String, dynamic>? leaderboard,
    Map<String, dynamic>? lastActivity,
  }) =>
      ItqanJourneyState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        profile: profile ?? this.profile,
        tasks: tasks ?? this.tasks,
        journey: journey ?? this.journey,
        streak: streak ?? this.streak,
        achievements: achievements ?? this.achievements,
        leaderboard: leaderboard ?? this.leaderboard,
        lastActivity: lastActivity ?? this.lastActivity,
      );
}

class ItqanJourneyException implements Exception {
  const ItqanJourneyException(
    this.status,
    this.message, {
    this.code,
    this.retryAfter,
    this.queued = false,
    this.validationErrors,
  });

  final int status;
  final String message;
  final String? code;
  final int? retryAfter;
  final bool queued;
  final Map<String, dynamic>? validationErrors;

  @override
  String toString() {
    final fields = validationErrors?.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' • ');
    return fields == null || fields.isEmpty ? message : '$message • $fields';
  }
}

class ItqanJourneyRepository {
  ItqanJourneyRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue:
                      'https://blueviolet-viper-439935.hostingersite.com',
                ))
            .replaceAll(RegExp(r'/$'), '');

  static const String _outboxName = 'itqan_activity_outbox';
  static const Uuid _uuid = Uuid();
  final http.Client _client;
  final String _base;
  Future<void>? _pendingSync;

  Future<Map<String, dynamic>> get(String endpoint) async =>
      _data(await _request('GET', endpoint));

  Future<Map<String, dynamic>> record(
    String type, {
    Map<String, dynamic>? metadata,
    String? sourceType,
    int? sourceId,
  }) async {
    final idempotencyKey = _uuid.v4();
    final body = <String, dynamic>{
      'activity_type': type,
      'idempotency_key': idempotencyKey,
      if (metadata != null) 'metadata': metadata,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
    };
    final ownerEmail = (await AuthService.getUser())?['email'] ?? '';
    final ownerId = await AuthService.getUserId();
    final outbox = await _openOutbox();
    await outbox.put(idempotencyKey, {
      'owner_email': ownerEmail,
      'owner_identity': ownerId == null
          ? (ownerEmail.trim().isEmpty
              ? ''
              : 'email:${ownerEmail.toLowerCase()}')
          : 'id:$ownerId',
      'body': body,
    });

    try {
      final result = await _request('POST', 'gamification/activities', body);
      await outbox.delete(idempotencyKey);
      return result;
    } on ItqanJourneyException catch (error) {
      if (!_isRetryable(error)) {
        await _markBlocked(outbox, idempotencyKey, error);
      } else {
        await _scheduleRetry(outbox, idempotencyKey, error);
        throw ItqanJourneyException(
          error.status,
          error.message,
          code: error.code,
          retryAfter: error.retryAfter,
          queued: true,
          validationErrors: error.validationErrors,
        );
      }
      rethrow;
    }
  }

  /// Retries queued events with the exact same idempotency key. The backend
  /// remains the sole source of rewards; queued events do not change balances.
  Future<void> syncPendingActivities() {
    final active = _pendingSync;
    if (active != null) return active;
    late final Future<void> shared;
    shared = _drainPendingActivities().whenComplete(() {
      if (identical(_pendingSync, shared)) _pendingSync = null;
    });
    _pendingSync = shared;
    return shared;
  }

  Future<void> _drainPendingActivities() async {
    final currentEmail = (await AuthService.getUser())?['email'];
    final currentUserId = await AuthService.getUserId();
    final identity = currentUserId != null
        ? 'id:$currentUserId'
        : currentEmail == null || currentEmail.trim().isEmpty
            ? ''
            : 'email:${currentEmail.toLowerCase()}';
    if (identity.isEmpty) return;

    final outbox = await _openOutbox();
    for (final key in outbox.keys.toList()) {
      final raw = outbox.get(key);
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final storedIdentity = entry['owner_identity']?.toString();
      final matchesUser = storedIdentity != null
          ? storedIdentity == identity
          : entry['owner_email'] == currentEmail;
      if (!matchesUser || entry['body'] is! Map) continue;
      if (entry['blocked_error'] != null) continue;
      final retryAt = DateTime.tryParse('${entry['retry_after_at'] ?? ''}');
      if (retryAt != null && retryAt.isAfter(DateTime.now())) continue;
      final body = Map<String, dynamic>.from(entry['body'] as Map);
      try {
        await _request('POST', 'gamification/activities', body);
        await outbox.delete(key);
      } on ItqanJourneyException catch (error) {
        if (!_isRetryable(error)) {
          await _markBlocked(outbox, key, error);
          continue;
        }
        await _scheduleRetry(outbox, key, error);
        // Avoid hammering the service after a transient failure or rate limit.
        break;
      }
    }
  }

  bool _isRetryable(ItqanJourneyException error) =>
      error.status == 0 ||
      error.status == 401 ||
      error.status == 408 ||
      error.status == 429 ||
      error.status >= 500;

  Future<void> _scheduleRetry(
    Box<dynamic> outbox,
    dynamic key,
    ItqanJourneyException error,
  ) async {
    final raw = outbox.get(key);
    if (raw is! Map) return;
    final entry = Map<String, dynamic>.from(raw);
    final delay = error.retryAfter ?? 30;
    if (error.status == 429 || error.retryAfter != null) {
      entry['retry_after_at'] =
          DateTime.now().add(Duration(seconds: delay)).toIso8601String();
    }
    await outbox.put(key, entry);
  }

  Future<void> _markBlocked(
    Box<dynamic> outbox,
    dynamic key,
    ItqanJourneyException error,
  ) async {
    final raw = outbox.get(key);
    if (raw is! Map) return;
    final entry = Map<String, dynamic>.from(raw);
    entry['blocked_error'] = error.message;
    entry['blocked_status'] = error.status;
    if (error.validationErrors != null) {
      entry['validation_errors'] = error.validationErrors;
    }
    await outbox.put(key, entry);
  }

  Future<Box<dynamic>> _openOutbox() async {
    if (!Hive.isBoxOpen(_outboxName)) await Hive.openBox(_outboxName);
    return Hive.box(_outboxName);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw const ItqanJourneyException(
        401,
        'يرجى تسجيل الدخول لاستخدام الرحلة.',
      );
    }

    late http.Response response;
    try {
      final uri = Uri.parse('$_base/api/v1/$path');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      response = method == 'GET'
          ? await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15))
          : await _client
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ItqanJourneyException(0, 'تعذر الاتصال: $error');
    }

    Map<String, dynamic> decoded = {};
    try {
      final value = jsonDecode(response.body);
      if (value is Map) decoded = Map<String, dynamic>.from(value);
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw ItqanJourneyException(
          response.statusCode,
          'استجابة الخادم غير صالحة. حاول التحديث لاحقًا.',
        );
      }
    }

    if (response.statusCode == 401) {
      await AuthService.logout();
      throw const ItqanJourneyException(
        401,
        'انتهت الجلسة. سجل الدخول مجدداً.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] is Map
          ? Map<String, dynamic>.from(decoded['error'] as Map)
          : decoded;
      throw ItqanJourneyException(
        response.statusCode,
        '${error['message'] ?? decoded['message'] ?? 'فشل الطلب (${response.statusCode})'}',
        code: error['code']?.toString(),
        retryAfter: error['retry_after'] is num
            ? (error['retry_after'] as num).toInt()
            : null,
        validationErrors: error['errors'] is Map
            ? Map<String, dynamic>.from(error['errors'] as Map)
            : decoded['errors'] is Map
                ? Map<String, dynamic>.from(decoded['errors'] as Map)
                : null,
      );
    }
    return decoded;
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      Map<String, dynamic>.from(response['data'] as Map);
}

class ItqanJourneyNotifier extends StateNotifier<ItqanJourneyState> {
  ItqanJourneyNotifier(this.repository) : super(const ItqanJourneyState());

  final ItqanJourneyRepository repository;
  Future<void>? _loadAllTask;

  Future<void> loadAll() {
    final active = _loadAllTask;
    if (active != null) return active;
    late final Future<void> shared;
    shared = _performLoadAll().whenComplete(() {
      if (identical(_loadAllTask, shared)) _loadAllTask = null;
    });
    _loadAllTask = shared;
    return shared;
  }

  Future<void> _performLoadAll() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await repository.syncPendingActivities();
      final results = await Future.wait([
        repository.get('gamification/profile'),
        repository.get('gamification/tasks'),
        repository.get('gamification/journey'),
        repository.get('gamification/streak'),
        repository.get('gamification/achievements'),
      ]);
      state = state.copyWith(
        loading: false,
        profile: results[0],
        tasks: results[1],
        journey: results[2],
        streak: results[3],
        achievements: results[4],
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }

  Future<Map<String, dynamic>> recordActivity(
    String type, {
    Map<String, dynamic>? metadata,
    String? sourceType,
    int? sourceId,
  }) async {
    final result = await repository.record(
      type,
      metadata: metadata,
      sourceType: sourceType,
      sourceId: sourceId,
    );
    final rawData = result['data'];
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : result;
    state = state.copyWith(lastActivity: data, clearError: true);
    await loadAll();
    return result;
  }

  Future<void> refreshProfile() async =>
      _refresh('gamification/profile', 'profile');
  Future<void> refreshJourney() async =>
      _refresh('gamification/journey', 'journey');
  Future<void> refreshLeaderboard() async =>
      _refresh('gamification/leaderboard?limit=10', 'leaderboard');
  Future<void> refreshAchievements() async =>
      _refresh('gamification/achievements', 'achievements');

  Future<void> _refresh(String endpoint, String key) async {
    try {
      final result = await repository.get(endpoint);
      state = switch (key) {
        'profile' => state.copyWith(profile: result, clearError: true),
        'journey' => state.copyWith(journey: result, clearError: true),
        'achievements' =>
          state.copyWith(achievements: result, clearError: true),
        _ => state.copyWith(leaderboard: result, clearError: true),
      };
    } catch (error) {
      state = state.copyWith(error: '$error');
    }
  }
}
