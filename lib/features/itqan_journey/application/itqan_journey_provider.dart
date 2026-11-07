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
  });

  final int status;
  final String message;
  final String? code;
  final int? retryAfter;

  @override
  String toString() => message;
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

  Future<Map<String, dynamic>> get(String endpoint) async =>
      _data(await _request('GET', endpoint));

  Future<Map<String, dynamic>> record(
    String type, {
    Map<String, dynamic>? metadata,
  }) async {
    final idempotencyKey = _uuid.v4();
    final body = <String, dynamic>{
      'activity_type': type,
      'idempotency_key': idempotencyKey,
      if (metadata != null) 'metadata': metadata,
    };
    final ownerEmail = (await AuthService.getUser())?['email'];
    final outbox = await _openOutbox();
    if (ownerEmail != null && ownerEmail.isNotEmpty) {
      await outbox.put(idempotencyKey, {
        'owner_email': ownerEmail,
        'body': body,
      });
    }

    try {
      final result = await _request('POST', 'gamification/activities', body);
      await outbox.delete(idempotencyKey);
      return result;
    } on ItqanJourneyException catch (error) {
      // Validation/client errors cannot succeed on an identical retry.
      if (error.status >= 400 &&
          error.status < 500 &&
          error.status != 401 &&
          error.status != 408 &&
          error.status != 429) {
        await outbox.delete(idempotencyKey);
      }
      rethrow;
    }
  }

  /// Retries queued events with the exact same idempotency key. The backend
  /// remains the sole source of rewards; queued events do not change balances.
  Future<void> syncPendingActivities() async {
    final currentEmail = (await AuthService.getUser())?['email'];
    if (currentEmail == null || currentEmail.isEmpty) return;

    final outbox = await _openOutbox();
    for (final key in outbox.keys.toList()) {
      final raw = outbox.get(key);
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      if (entry['owner_email'] != currentEmail || entry['body'] is! Map) {
        continue;
      }
      final body = Map<String, dynamic>.from(entry['body'] as Map);
      try {
        await _request('POST', 'gamification/activities', body);
        await outbox.delete(key);
      } on ItqanJourneyException catch (error) {
        if (error.status >= 400 &&
            error.status < 500 &&
            error.status != 401 &&
            error.status != 408 &&
            error.status != 429) {
          await outbox.delete(key);
        }
        rethrow;
      }
    }
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

  Future<void> loadAll() async {
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
  }) async {
    final result = await repository.record(type, metadata: metadata);
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
