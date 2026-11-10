import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class FirebaseAuthApiException implements Exception {
  const FirebaseAuthApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthApi {
  FirebaseAuthApi({http.Client? client, String? baseUrl})
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

  Future<void> exchangeFirebaseIdToken(String idToken) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/v1/auth/firebase'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> decoded = <String, dynamic>{};
    try {
      final value = jsonDecode(response.body);
      if (value is Map) decoded = Map<String, dynamic>.from(value);
    } catch (_) {
      // The status code below still produces a useful Arabic error.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseAuthApiException(
        response.statusCode,
        '${decoded['message'] ?? 'تعذر تسجيل الدخول عبر Google (${response.statusCode}).'}',
      );
    }

    final data = decoded['data'];
    if (data is! Map || data['token'] == null) {
      throw const FirebaseAuthApiException(
        200,
        'استجابة المصادقة لا تحتوي على token صالح.',
      );
    }
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    final token = '${data['token']}';
    await AuthService.saveSession(
      name: '${user['name'] ?? ''}',
      email: '${user['email'] ?? ''}',
      token: token,
      userId: user['id'] is num ? (user['id'] as num).toInt() : null,
    );
  }
}
