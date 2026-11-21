import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../domain/circle_models.dart';

class CircleApiException implements Exception {
  final int status;
  final String message;
  const CircleApiException(this.status, this.message);
  @override
  String toString() => message;
}

class CircleApiService {
  CircleApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ??
                const String.fromEnvironment('API_BASE_URL',
                    defaultValue:
                        'https://blueviolet-viper-439935.hostingersite.com'))
            .replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _base;

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<CircleTypeInfo>> fetchTypes() async {
    final r = await _client.get(Uri.parse('$_base/api/v1/circle-types'),
        headers: await _headers());
    final d = _decode(r);
    final list = d['data'] as List<dynamic>? ?? [];
    return list
        .map(
            (t) => CircleTypeInfo.fromJson(Map<String, dynamic>.from(t as Map)))
        .toList();
  }

  Future<List<CircleModel>> fetchMyCircles() async {
    final r = await _client.get(Uri.parse('$_base/api/v1/circles/my'),
        headers: await _headers());
    final d = _decode(r);
    final list = d['data'] as List<dynamic>? ?? [];
    return list
        .map((c) => CircleModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  Future<ActiveCircleContext> createCircle({
    required String name,
    required String type,
    String? description,
    String? relationship,
  }) async {
    final body = {
      'name': name,
      'type': type,
      if (description != null) 'description': description,
      if (relationship != null) 'relationship': relationship,
    };
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final d = _decode(r);
    return _parseContext(d['data'] as Map<String, dynamic>);
  }

  Future<ActiveCircleContext> fetchCircleDashboard(String uuid) async {
    final r = await _client.get(
      Uri.parse('$_base/api/v1/circles/$uuid/dashboard'),
      headers: await _headers(),
    );
    final d = _decode(r);
    return _parseContext(d['data'] as Map<String, dynamic>);
  }

  Future<List<CircleMemberModel>> fetchMembers(String circleUuid) async {
    final r = await _client.get(
      Uri.parse('$_base/api/v1/circles/$circleUuid/members'),
      headers: await _headers(),
    );
    final d = _decode(r);
    final list = d['data'] as List<dynamic>? ?? [];
    return list
        .map((m) =>
            CircleMemberModel.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<void> createManagedProfile(
    String circleUuid, {
    required String displayName,
    required String ageGroup,
    String? relationship,
  }) async {
    final body = {
      'display_name': displayName,
      'age_group': ageGroup,
      if (relationship != null) 'relationship': relationship,
    };
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/members/profile'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _decode(r);
  }

  Future<Map<String, dynamic>> createInvitation(
    String circleUuid, {
    String role = 'member',
    String? relationship,
    int expiresInMinutes = 15,
  }) async {
    final body = {
      'role': role,
      if (relationship != null) 'relationship': relationship,
      'expires_in_minutes': expiresInMinutes,
    };
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/invitations'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final d = _decode(r);
    return Map<String, dynamic>.from(d['data'] as Map);
  }

  Future<Map<String, dynamic>> previewInvitation(String code) async {
    final r = await _client.post(
      Uri.parse('$_base/api/v1/invitations/preview'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    final d = _decode(r);
    return Map<String, dynamic>.from(d['data'] as Map);
  }

  Future<ActiveCircleContext> redeemInvitation(String code) async {
    final r = await _client.post(
      Uri.parse('$_base/api/v1/invitations/redeem'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    final d = _decode(r);
    return _parseContext(d['data'] as Map<String, dynamic>);
  }

  Future<List<CircleActivityModel>> fetchActivities(String circleUuid) async {
    final r = await _client.get(
      Uri.parse('$_base/api/v1/circles/$circleUuid/activities'),
      headers: await _headers(),
    );
    final d = _decode(r);
    final list = d['data'] as List<dynamic>? ?? [];
    return list
        .map((a) =>
            CircleActivityModel.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> fetchLeaderDashboard(String circleUuid) async {
    final response = await _client.get(
      Uri.parse('$_base/api/v1/circles/$circleUuid/leader-dashboard'),
      headers: await _headers(),
    );
    final decoded = _decode(response);
    final data = decoded['data'];
    if (data is! Map) {
      throw const CircleApiException(
        502,
        'استجابة لوحة القائد غير صالحة',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchLessons(String circleUuid) async {
    final response = await _client.get(
      Uri.parse('$_base/api/v1/circles/$circleUuid/lessons'),
      headers: await _headers(),
    );
    final decoded = _decode(response);
    final data = decoded['data'];
    if (data is! List) {
      throw const CircleApiException(502, 'قائمة الدروس غير صالحة');
    }
    return data
        .whereType<Map>()
        .map((lesson) => Map<String, dynamic>.from(lesson))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> fetchLesson(String lessonUuid) async {
    final response = await _client.get(
      Uri.parse('$_base/api/v1/lessons/$lessonUuid'),
      headers: await _headers(),
    );
    final decoded = _decode(response);
    final data = decoded['data'];
    if (data is! Map) {
      throw const CircleApiException(502, 'بيانات الدرس غير صالحة');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> createLesson(
    String circleUuid, {
    required String title,
    required String youtubeUrl,
  }) async {
    final response = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/lessons'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title.trim(),
        'youtube_url': youtubeUrl.trim(),
      }),
    );
    final decoded = _decode(response);
    final data = decoded['data'];
    if (data is! Map) {
      throw const CircleApiException(502, 'استجابة إنشاء الدرس غير صالحة');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> deleteLesson(String lessonUuid) async {
    final response = await _client.delete(
      Uri.parse('$_base/api/v1/lessons/$lessonUuid'),
      headers: await _headers(),
    );
    _decode(response);
  }

  Future<CircleActivityModel> createActivity(
    String circleUuid, {
    required String title,
    required String type,
    int targetCount = 100,
  }) async {
    final body = {
      'title': title,
      'type': type,
      'target_count': targetCount,
    };
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/activities'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final d = _decode(r);
    return CircleActivityModel.fromJson(
        Map<String, dynamic>.from(d['data'] as Map));
  }

  Future<Map<String, dynamic>> incrementActivity(
    String activityUuid, {
    int step = 1,
    required String idempotencyKey,
  }) async {
    final body = {
      'step': step,
      'idempotency_key': idempotencyKey,
    };
    final r = await _client.post(
      Uri.parse('$_base/api/v1/activities/$activityUuid/increment'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final d = _decode(r);
    return Map<String, dynamic>.from(d['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> fetchWhisperTemplates() async {
    final headers = await _headers();
    for (final path in [
      '/api/v1/whisper-templates',
      '/api/v1/whispers/templates',
    ]) {
      final response = await _client.get(
        Uri.parse('$_base$path'),
        headers: headers,
      );
      final body = _decode(response);
      final rawList = _extractWhisperTemplates(body);
      if (rawList == null) {
        throw const CircleApiException(502, 'صيغة قوالب الهمسات غير صالحة');
      }

      final templates = rawList.map((raw) {
        if (raw is! Map || raw['key'] == null) {
          throw const CircleApiException(
              502, 'بيانات أحد قوالب الهمسات غير صالحة');
        }
        final template = Map<String, dynamic>.from(raw);
        final text = [
          template['text_ar'],
          template['text'],
          template['content'],
          template['message'],
          template['body'],
          template['title'],
        ].map((value) => value?.toString().trim() ?? '').firstWhere(
              (value) => value.isNotEmpty,
              orElse: () => '',
            );
        if (text.isEmpty) {
          throw const CircleApiException(
              502, 'بيانات أحد قوالب الهمسات غير صالحة');
        }
        template['text_ar'] = text;
        return template;
      }).toList();
      if (templates.isNotEmpty || path == '/api/v1/whispers/templates') {
        return templates;
      }
    }
    return [];
  }

  List<dynamic>? _extractWhisperTemplates(Map<String, dynamic> body) {
    dynamic value = body['data'] ?? body['templates'];
    for (var depth = 0; depth < 3; depth++) {
      if (value is List) return value;
      if (value is! Map) return null;
      value = value['data'] ?? value['templates'];
    }
    return null;
  }

  Future<List<CircleWhisperModel>> fetchWhispers(String circleUuid) async {
    final r = await _client.get(
      Uri.parse('$_base/api/v1/circles/$circleUuid/whispers'),
      headers: await _headers(),
    );
    final d = _decode(r);
    final list = d['data'] as List<dynamic>? ?? [];
    return list
        .map((w) =>
            CircleWhisperModel.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();
  }

  Future<void> sendWhisper(
    String circleUuid, {
    required String templateKey,
    int? recipientUserId,
    required bool isAnonymous,
    String? messageText,
  }) async {
    final normalizedMessage =
        messageText?.trim().isNotEmpty == true ? messageText!.trim() : null;
    final body = {
      'recipient_user_id': recipientUserId,
      'recipient_ids': recipientUserId == null ? null : <int>[recipientUserId],
      'template_key': templateKey,
      'is_anonymous': isAnonymous,
      'message_text': normalizedMessage,
      'custom_text': normalizedMessage,
    };
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/whispers'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _decode(r);
  }

  Future<void> respondWhisper(String whisperUuid, String responseKey) async {
    final body = {'response_key': responseKey};
    final r = await _client.post(
      Uri.parse('$_base/api/v1/whispers/$whisperUuid/respond'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _decode(r);
  }

  Future<void> leaveCircle(String circleUuid) async {
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/leave'),
      headers: await _headers(),
    );
    _decode(r);
  }

  Future<void> removeCircleMember(String circleUuid, int userId) async {
    final r = await _client.delete(
      Uri.parse('$_base/api/v1/circles/$circleUuid/members/$userId'),
      headers: await _headers(),
    );
    _decode(r);
  }

  Future<void> updateCircleMemberRole(
    String circleUuid, {
    required int userId,
    required String role,
  }) async {
    final r = await _client.patch(
      Uri.parse('$_base/api/v1/circles/$circleUuid/members/$userId/role'),
      headers: await _headers(),
      body: jsonEncode({'role': role}),
    );
    _decode(r);
  }

  Future<void> transferCircleOwnership(
    String circleUuid, {
    required int newOwnerId,
  }) async {
    final r = await _client.post(
      Uri.parse('$_base/api/v1/circles/$circleUuid/transfer-ownership'),
      headers: await _headers(),
      body: jsonEncode({'new_owner_id': newOwnerId}),
    );
    _decode(r);
  }

  Future<void> deleteCircle(String circleUuid) async {
    final r = await _client.delete(
      Uri.parse('$_base/api/v1/circles/$circleUuid'),
      headers: await _headers(),
    );
    _decode(r);
  }

  ActiveCircleContext _parseContext(Map<String, dynamic> data) {
    final circleMap = data['circle'] as Map<String, dynamic>? ?? data;
    final permsList =
        (data['permissions'] as List<dynamic>? ?? []).cast<String>();
    final expMap = data['experience'] as Map<String, dynamic>? ?? {};
    final modulesList =
        (expMap['enabled_modules'] as List<dynamic>? ?? []).cast<String>();

    return ActiveCircleContext(
      circle: CircleModel.fromJson(circleMap),
      permissions: permsList,
      enabledModules: modulesList,
      dashboardKey: expMap['dashboard_key']?.toString() ?? 'family_member',
    );
  }

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> body = {};
    if (r.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } on FormatException {
        if (r.statusCode >= 200 && r.statusCode < 300) {
          throw const CircleApiException(502, 'رد الخادم ليس بصيغة JSON صالحة');
        }
      }
    }

    if (r.statusCode == 401) {
      AuthService.expireSession().catchError((error) {
        debugPrint('Failed to handle an expired circle API session: $error');
      });
    }

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final err = body['error'];
      final serverMessage = body['message']?.toString();
      final baseMessage = err is Map
          ? err['message']?.toString()
          : (err?.toString() ?? serverMessage);
      final validationErrors = body['errors'];
      if (r.statusCode == 422 && validationErrors is Map) {
        final details = validationErrors.entries
            .map((entry) {
              final messages = entry.value is List
                  ? (entry.value as List)
                      .map((value) => value.toString())
                      .join('، ')
                  : entry.value.toString();
              return messages;
            })
            .where((message) => message.isNotEmpty)
            .join('، ');
        throw CircleApiException(
          422,
          details.isNotEmpty
              ? 'البيانات غير مقبولة: $details'
              : (baseMessage ?? 'يرجى مراجعة بيانات الهمسة'),
        );
      }
      throw CircleApiException(
        r.statusCode,
        baseMessage ?? 'حدث خطأ في الخادم (${r.statusCode})',
      );
    }
    return body;
  }
}
