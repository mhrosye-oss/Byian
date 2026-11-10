import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/auth_service.dart';
import '../domain/circle_api_errors.dart';

class CircleApiService {
  CircleApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue:
                      'https://blueviolet-viper-439935.hostingersite.com',
                ))
            .replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<List<Map<String, dynamic>>> getTypes() async =>
      _list(await _request('GET', 'circles/types', authenticated: false));

  Future<List<Map<String, dynamic>>> getMyCircles() async =>
      _list(await _request('GET', 'circles/my'));

  Future<Map<String, dynamic>> createCircle(
          {required int typeId,
          required String name,
          String? description}) async =>
      _map(await _request('POST', 'circles', body: {
        'type_id': typeId,
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      }));

  Future<Map<String, dynamic>> getDashboard(String uuid) async =>
      _map(await _request('GET', 'circles/$uuid/dashboard'));

  Future<void> completeTask(String taskId) async {
    await _request('POST', 'circle-tasks/$taskId/complete');
  }

  Future<void> leaveCircle(String uuid) async {
    await _request('POST', 'circles/$uuid/leave');
  }

  Future<List<Map<String, dynamic>>> getMembers(String uuid) async =>
      _list(await _request('GET', 'circles/$uuid/members'));

  Future<List<Map<String, dynamic>>> getActivities(String uuid) async =>
      _list(await _request('GET', 'circles/$uuid/activities'));

  Future<List<Map<String, dynamic>>> getWhispers(String uuid) async =>
      _list(await _request('GET', 'circles/$uuid/whispers'));

  Future<Map<String, dynamic>> generateInvite(String uuid) async =>
      _map(await _request(
        'POST',
        'circles/$uuid/invitations',
        body: const {
          'suggested_role': 'member',
          'max_uses': 5,
          'valid_hours': 168
        },
      ));

  Future<Map<String, dynamic>> previewInvitation(String code) async =>
      _map(await _request(
        'POST',
        'invitations/preview',
        body: {'code': code},
        authenticated: false,
      ));

  Future<Map<String, dynamic>> redeemInvitation(String code) async =>
      _map(await _request(
        'POST',
        'invitations/redeem',
        body: {'code': code},
      ));

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw const CircleApiException(
            401, 'يرجى تسجيل الدخول لاستخدام الدوائر.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/$path');
      final encodedBody = body == null
          ? null
          : jsonEncode(body);
      final request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.post(uri, headers: headers, body: encodedBody),
      };
      response = await request.timeout(const Duration(seconds: 20));
    } on CircleApiException {
      rethrow;
    } catch (error) {
      throw CircleApiException(0, 'تعذر الاتصال بالخادم: $error');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw CircleApiException(
          response.statusCode, 'استجابة الخادم غير صالحة.');
    }

    if (response.statusCode == 401) {
      await AuthService.logout();
      throw const CircleApiException(401, 'انتهت الجلسة. سجل الدخول مجددًا.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final map = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      final error = map['error'] is Map
          ? Map<String, dynamic>.from(map['error'] as Map)
          : map;
      throw CircleApiException(
        response.statusCode,
        '${error['message'] ?? map['message'] ?? 'فشل الطلب (${response.statusCode}).'}',
        validationErrors: error['errors'] is Map
            ? Map<String, dynamic>.from(error['errors'] as Map)
            : null,
      );
    }
    return decoded;
  }

  dynamic _data(dynamic response) =>
      response is Map && response.containsKey('data')
          ? response['data']
          : response;

  List<Map<String, dynamic>> _list(dynamic response) {
    final data = _data(response);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _map(dynamic response) {
    final data = _data(response);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const CircleApiException(
        0, 'بيانات الدائرة الواردة من الخادم غير صالحة.');
  }
}
