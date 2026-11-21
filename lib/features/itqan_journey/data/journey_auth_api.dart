import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';

class JourneyAuthException implements Exception {
  const JourneyAuthException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}

class JourneyAuthApi {
  JourneyAuthApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ??
                const String.fromEnvironment('API_BASE_URL',
                    defaultValue:
                        'https://blueviolet-viper-439935.hostingersite.com'))
            .replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _base;

  Future<Map<String, dynamic>> login(String email, String password) =>
      _send('auth/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> register(
      {required String name,
      required String email,
      required String password,
      String? phone}) {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    return _send('auth/register', body, method: 'POST');
  }

  // New method: Firebase login using ID token from Google Sign-In
  Future<Map<String, dynamic>> firebaseLogin({required String idToken}) async {
    final locale = await AuthService.getPreferredLocale();
    return _send('auth/firebase', {'id_token': idToken, 'locale': locale});
  }

  // New method: Register FCM push installation
  Future<void> registerPushInstallation(
      {required String installationId, required String platform}) async {
    await _send('me/push-installations',
        {'installation_id': installationId, 'platform': platform});
  }

  Future<Map<String, dynamic>> me() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw const JourneyAuthException(401, 'يرجى تسجيل الدخول.');
    }
    final r = await _client.get(Uri.parse('$_base/api/v1/auth/me'), headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    });
    if (r.statusCode == 401) {
      var message = '';
      try {
        final response = jsonDecode(r.body);
        if (response is Map) {
          message = response['message']?.toString() ?? '';
        }
      } on FormatException {
        message = '';
      }
      if (message == 'Invalid or expired token') {
        await AuthService.expireSession();
      }
      if (message == 'Unauthenticated') {
        throw const JourneyAuthException(
          401,
          'لم يُرسل التوكن مع الطلب؛ تحقق من إعدادات المصادقة.',
        );
      }
      if (message != 'Invalid or expired token') {
        throw JourneyAuthException(
          401,
          message.isEmpty ? 'تعذر التحقق من الجلسة.' : message,
        );
      }
      throw const JourneyAuthException(401, 'انتهت الجلسة.');
    }
    if (r.statusCode != 200) {
      throw JourneyAuthException(
          r.statusCode, 'تعذر تحميل الحساب (${r.statusCode}).');
    }
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  Future<void> updateLocale(String locale) async {
    final token = await AuthService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw const JourneyAuthException(401, 'يرجى تسجيل الدخول.');
    }

    try {
      final response = await _client.patch(
        Uri.parse('$_base/api/v1/me/locale'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'locale': locale}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        Map<String, dynamic> body = {};
        try {
          body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
        } on FormatException {
          body = {};
        }
        throw JourneyAuthException(
          response.statusCode,
          body['message']?.toString() ?? 'تعذر تحديث لغة الحساب.',
        );
      }
    } on JourneyAuthException {
      rethrow;
    } catch (error) {
      throw JourneyAuthException(0, 'تعذر تحديث لغة الحساب: $error');
    }
  }

  Future<void> logout() async {
    final token = await AuthService.getToken();
    if (token != null) {
      try {
        await _client.post(Uri.parse('$_base/api/v1/auth/logout'), headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        });
      } finally {
        await AuthService.logout();
      }
    } else {
      await AuthService.logout();
    }
  }

  Future<Map<String, dynamic>> _send(String path, Map<String, dynamic> body,
      {String method = 'POST'}) async {
    try {
      final r = await _client.post(Uri.parse('$_base/api/v1/$path'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));
      Map<String, dynamic> d = {};
      try {
        d = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
      } catch (_) {}
      if (r.statusCode != 200 && r.statusCode != 201) {
        final errors = d['errors'];
        final message = errors is Map
            ? errors.values.first.toString()
            : d['message']?.toString() ??
                'تعذر إتمام المصادقة (${r.statusCode}).';
        throw JourneyAuthException(r.statusCode, message);
      }
      final user = Map<String, dynamic>.from((d['data'] as Map)['user'] as Map);
      final token = ((d['data'] as Map)['token'] ?? '').toString();
      if (token.isEmpty) {
        throw const JourneyAuthException(
            200, 'استجابة الخادم لا تحتوي على token صالح.');
      }
      await AuthService.saveSession(
        name: (user['name'] ?? '').toString(),
        email: (user['email'] ?? '').toString(),
        token: token,
        userId: user['id'] is num ? (user['id'] as num).toInt() : null,
      );
      return d;
    } on JourneyAuthException {
      rethrow;
    } catch (e) {
      throw JourneyAuthException(0, 'تعذر الاتصال بخدمة المصادقة: $e');
    }
  }
}
