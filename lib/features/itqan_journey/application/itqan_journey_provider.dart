import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../core/services/auth_service.dart';

final itqanJourneyRepositoryProvider =
    Provider<ItqanJourneyRepository>((ref) => ItqanJourneyRepository());
final itqanJourneyProvider =
    StateNotifierProvider<ItqanJourneyNotifier, ItqanJourneyState>((ref) =>
        ItqanJourneyNotifier(ref.read(itqanJourneyRepositoryProvider)));

class ItqanJourneyState {
  const ItqanJourneyState(
      {this.loading = false,
      this.error,
      this.profile,
      this.tasks,
      this.journey,
      this.streak,
      this.achievements,
      this.leaderboard,
      this.lastActivity});
  final bool loading;
  final String? error;
  final Map<String, dynamic>? profile,
      tasks,
      journey,
      streak,
      achievements,
      leaderboard,
      lastActivity;
  ItqanJourneyState copyWith(
          {bool? loading,
          String? error,
          bool clearError = false,
          Map<String, dynamic>? profile,
          tasks,
          journey,
          streak,
          achievements,
          leaderboard,
          lastActivity}) =>
      ItqanJourneyState(
          loading: loading ?? this.loading,
          error: clearError ? null : (error ?? this.error),
          profile: profile ?? this.profile,
          tasks: tasks ?? this.tasks,
          journey: journey ?? this.journey,
          streak: streak ?? this.streak,
          achievements: achievements ?? this.achievements,
          leaderboard: leaderboard ?? this.leaderboard,
          lastActivity: lastActivity ?? this.lastActivity);
}

class ItqanJourneyException implements Exception {
  const ItqanJourneyException(this.status, this.message,
      {this.code, this.retryAfter});
  final int status;
  final String message;
  final String? code;
  final int? retryAfter;
  @override
  String toString() => message;
}

class ItqanJourneyRepository {
  ItqanJourneyRepository(
      {http.Client? client,
      String? baseUrl,
      Future<String?> Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _base = (baseUrl ??
                const String.fromEnvironment('API_BASE_URL',
                    defaultValue:
                        'https://blueviolet-viper-439935.hostingersite.com'))
            .replaceAll(RegExp(r'/$'), ''),
        _tokenProvider = tokenProvider ?? AuthService.getToken;
  final http.Client _client;
  final String _base;
  final Future<String?> Function() _tokenProvider;
  static const _uuid = Uuid();
  Future<Map<String, dynamic>> get(String endpoint) async =>
      _data(await _request('GET', endpoint));
  Future<Map<String, dynamic>> record(String type,
      {Map<String, dynamic>? metadata}) async {
    final body = <String, dynamic>{
      'activity_type': type,
      'idempotency_key': _uuid.v4()
    };
    if (metadata != null) body['metadata'] = metadata;
    return _request('POST', 'gamification/activities', body);
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const ItqanJourneyException(
          401, 'يرجى تسجيل الدخول لاستخدام الرحلة.');
    }
    late http.Response response;
    try {
      final uri = Uri.parse('$_base/api/v1/$path');
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      };
      response = method == 'GET'
          ? await _client.get(uri, headers: headers)
          : await _client.post(uri, headers: headers, body: jsonEncode(body));
    } catch (e) {
      throw ItqanJourneyException(0, 'تعذر الاتصال: $e');
    }
    Map<String, dynamic> decoded = {};
    try {
      decoded = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {}
    if (response.statusCode == 401) {
      await AuthService.logout();
      throw const ItqanJourneyException(
          401, 'انتهت الجلسة. سجل الدخول مجدداً.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] is Map
          ? Map<String, dynamic>.from(decoded['error'] as Map)
          : decoded;
      throw ItqanJourneyException(response.statusCode,
          '${error['message'] ?? decoded['message'] ?? 'فشل الطلب (${response.statusCode})'}',
          code: error['code']?.toString(),
          retryAfter: error['retry_after'] is num
              ? (error['retry_after'] as num).toInt()
              : null);
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
      final r = await Future.wait([
        repository.get('gamification/profile'),
        repository.get('gamification/tasks'),
        repository.get('gamification/journey'),
        repository.get('gamification/streak'),
        repository.get('gamification/achievements')
      ]);
      state = state.copyWith(
          loading: false,
          profile: r[0],
          tasks: r[1],
          journey: r[2],
          streak: r[3],
          achievements: r[4],
          clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<Map<String, dynamic>> recordActivity(String type,
      {Map<String, dynamic>? metadata}) async {
    final result = await repository.record(type, metadata: metadata);
    final data = Map<String, dynamic>.from(result['data'] as Map);
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
        _ => state.copyWith(leaderboard: result, clearError: true)
      };
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }
}
