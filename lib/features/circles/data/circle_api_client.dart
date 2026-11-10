import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/circle_models.dart';
import 'circle_api_config.dart';
import 'circle_session_store.dart';

class CircleApiClient {
  CircleApiClient({
    CircleSessionStore? sessionStore,
    Dio? dio,
    String? baseUrl,
  })  : sessionStore = sessionStore ?? SecureCircleSessionStore(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl:
                    '${(baseUrl ?? CircleApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '')}${CircleApiConfig.apiPrefix}/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                headers: const {'Accept': 'application/json'},
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              options.headers['Accept'] = 'application/json';
              if (options.extra['circle_public'] != true) {
                final token = await this.sessionStore.readToken();
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              final response = error.response;
              if (response?.statusCode == 401) {
                final message = _messageFrom(response?.data);
                if (message == 'Invalid or expired token') {
                  await this.sessionStore.clear();
                  if (!_sessionExpired.isClosed) _sessionExpired.add(null);
                } else if (message == 'Unauthenticated') {
                  debugPrint(
                    'Circles auth bug: backend returned Unauthenticated; inspect the Dio Authorization interceptor.',
                  );
                }
                handler.reject(
                  error.copyWith(
                    error: CircleApiException(
                      401,
                      _userMessage(401, message),
                      isUnauthenticatedBug: message == 'Unauthenticated',
                    ),
                  ),
                );
                return;
              }
              handler.next(error);
            },
          ),
        );
  }

  static final CircleApiClient instance = CircleApiClient();

  final CircleSessionStore sessionStore;
  final Dio dio;
  final StreamController<void> _sessionExpired =
      StreamController<void>.broadcast();

  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<AppUser> exchangeFirebaseIdToken(String firebaseIdToken) async {
    final payload = await post(
      'auth/firebase',
      body: {'id_token': firebaseIdToken},
      authenticated: false,
    );
    final response = _asMap(payload);
    final token = response['token']?.toString();
    if (token == null || token.length != 64) {
      throw const CircleApiException(
        502,
        'استجابة تسجيل الدخول لا تحتوي على رمز جلسة صالح.',
      );
    }
    await sessionStore.saveToken(token);
    final userJson = _asMapOrNull(response['user']);
    if (userJson == null ||
        userJson['id'] == null ||
        userJson['name'] == null ||
        userJson['email'] == null) {
      return getMe();
    }
    final user = AppUser.fromJson(userJson);
    await sessionStore.saveUser(user);
    return user;
  }

  Future<AppUser> getMe() async {
    final payload = await get('auth/me');
    final data = _asMap(payload);
    final user = _asMapOrNull(data['user']) ?? data;
    final profile = AppUser.fromJson(user);
    await sessionStore.saveUser(profile);
    return profile;
  }

  Future<List<Circle>> getCircles() async =>
      (await _getList('circles')).map(Circle.fromJson).toList(growable: false);

  Future<List<CircleType>> getCircleTypes() async => (await _getList(
        'circles/types',
        authenticated: false,
      ))
          .map(CircleType.fromJson)
          .toList(growable: false);

  Future<Map<String, dynamic>> getCircle(String uuid) =>
      _getMap('circles/${_segment(uuid)}');

  Future<Map<String, dynamic>> getDashboard(String uuid) =>
      _getMap('circles/${_segment(uuid)}/dashboard');

  Future<List<Map<String, dynamic>>> getMembers(String uuid) =>
      _getList('circles/${_segment(uuid)}/members');

  Future<List<Map<String, dynamic>>> getActivities(String uuid) =>
      _getList('circles/${_segment(uuid)}/activities');

  Future<List<Map<String, dynamic>>> getCircleTasks(String uuid) =>
      _getList('circles/${_segment(uuid)}/tasks');

  /// The cross-circle endpoint is confirmed live. There is deliberately no
  /// N+1 fallback; a backend 404 is surfaced as an endpoint error.
  Future<List<CircleTask>> getMyTasks({
    String status = 'pending,in_progress',
  }) async =>
      (await _getList(
        'me/tasks',
        queryParameters: {'status': status},
      ))
          .map(CircleTask.fromJson)
          .toList(growable: false);

  Future<void> completeTask(String taskUuid) async {
    await post('circle-tasks/${_segment(taskUuid)}/complete');
  }

  Future<void> leaveCircle(String uuid) async {
    await post('circles/${_segment(uuid)}/leave');
  }

  Future<List<Map<String, dynamic>>> getWhispers(String uuid) =>
      _getList('circles/${_segment(uuid)}/whispers');

  Future<List<Map<String, dynamic>>> getWhisperTemplates() =>
      _getList('whisper-templates', authenticated: false);

  /// Mutations with server-defined request schemas accept an explicit payload.
  /// UI code must not invent fields; pass only a payload documented by the
  /// backend owner.
  Future<Map<String, dynamic>> createCircle(
    Map<String, dynamic> documentedPayload,
  ) async =>
      _asMap(await post('circles', body: documentedPayload));

  Future<Map<String, dynamic>> createTask(
    String circleUuid,
    Map<String, dynamic> documentedPayload,
  ) async =>
      _asMap(await post(
        'circles/${_segment(circleUuid)}/tasks',
        body: documentedPayload,
      ));

  Future<Map<String, dynamic>> createInvitation(
    String circleUuid,
    Map<String, dynamic> documentedPayload,
  ) async =>
      _asMap(await post(
        'circles/${_segment(circleUuid)}/invitations',
        body: documentedPayload,
      ));

  Future<Map<String, dynamic>> generateInvitation(String circleUuid) =>
      createInvitation(circleUuid, const {
        'suggested_role': 'member',
        'max_uses': 5,
        'valid_hours': 168,
      });

  Future<Map<String, dynamic>> previewInvitation(String code) async =>
      _asMap(await post(
        'invitations/preview',
        body: {'code': code},
        authenticated: false,
      ));

  Future<Map<String, dynamic>> redeemInvitation(String code) async =>
      _asMap(await post('invitations/redeem', body: {'code': code}));

  Future<void> sendWhisper(
    String circleUuid,
    Map<String, dynamic> documentedPayload,
  ) async {
    await post(
      'circles/${_segment(circleUuid)}/whispers',
      body: documentedPayload,
    );
  }

  Future<void> registerPushInstallation({
    required String installationId,
    required String platform,
  }) async {
    await post(
      'me/push-installations',
      body: {'installation_id': installationId, 'platform': platform},
    );
  }

  Future<void> unregisterPushInstallation(String installationId) async {
    await delete('me/push-installations/${_segment(installationId)}');
  }

  Future<void> logout() async {
    await post('auth/logout');
  }

  Future<dynamic> get(
    String path, {
    bool authenticated = true,
    Map<String, dynamic>? queryParameters,
  }) =>
      _request(
        'GET',
        path,
        authenticated: authenticated,
        queryParameters: queryParameters,
      );

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) =>
      _request('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> delete(
    String path, {
    bool authenticated = true,
  }) =>
      _request('DELETE', path, authenticated: authenticated);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (authenticated) {
      final token = await sessionStore.readToken();
      if (token == null || token.isEmpty) {
        throw const CircleApiException(401, 'يرجى تسجيل الدخول أولاً.');
      }
    }
    try {
      final response = await dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          extra: {'circle_public': !authenticated},
          contentType: body == null ? null : Headers.jsonContentType,
        ),
      );
      return _unwrap(response.data, response.statusCode ?? 200);
    } on CircleApiException {
      rethrow;
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is CircleApiException) throw mapped;
      final statusCode = error.response?.statusCode ?? 0;
      final message = _messageFrom(error.response?.data);
      throw CircleApiException(
        statusCode,
        message.isNotEmpty
            ? _userMessage(statusCode, message)
            : (statusCode == 0
                ? 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت.'
                : _userMessage(statusCode, '')),
        validationErrors: _validationErrors(error.response?.data),
      );
    } catch (error) {
      throw CircleApiException(0, 'تعذر تنفيذ الطلب: $error');
    }
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    bool authenticated = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    final value = await get(
      path,
      authenticated: authenticated,
      queryParameters: queryParameters,
    );
    if (value is! List) {
      throw const CircleApiException(
          502, 'صيغة قائمة البيانات من الخادم غير متوقعة.');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getMap(String path) async =>
      _asMap(await get(path));

  static dynamic _unwrap(dynamic raw, int statusCode) {
    final decoded = raw is String ? _decodeString(raw, statusCode) : raw;
    if (decoded is Map) {
      final root = Map<String, dynamic>.from(decoded);
      if (root['success'] == false) {
        final message = root['message']?.toString() ?? '';
        throw CircleApiException(
          statusCode,
          _userMessage(statusCode, message),
          validationErrors: _validationErrors(root),
          isUnauthenticatedBug: message == 'Unauthenticated',
        );
      }
      if (root.containsKey('data')) return root['data'];
      return root;
    }
    if (decoded is List) return decoded;
    if (decoded == null) return const <String, dynamic>{};
    throw const CircleApiException(502, 'صيغة استجابة الخادم غير متوقعة.');
  }

  static dynamic _decodeString(String raw, int statusCode) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      throw CircleApiException(statusCode, 'استجابة الخادم ليست JSON صالحًا.');
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    final map = _asMapOrNull(value);
    if (map == null) {
      throw const CircleApiException(502, 'صيغة بيانات الخادم غير متوقعة.');
    }
    return map;
  }

  static Map<String, dynamic>? _asMapOrNull(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static String _segment(String value) => Uri.encodeComponent(value);

  static String _messageFrom(dynamic value) {
    final decoded = value is String ? _tryDecode(value) : value;
    return decoded is Map ? decoded['message']?.toString() ?? '' : '';
  }

  static dynamic _tryDecode(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic>? _validationErrors(dynamic value) {
    final decoded = value is String ? _tryDecode(value) : value;
    if (decoded is! Map || decoded['errors'] is! Map) return null;
    return Map<String, dynamic>.from(decoded['errors'] as Map);
  }

  static String _userMessage(int statusCode, String backendMessage) {
    if (backendMessage == 'Invalid or expired token') {
      return 'انتهت صلاحية الجلسة. سجّل الدخول من جديد.';
    }
    if (backendMessage == 'Unauthenticated') {
      return 'تعذر إرسال رمز المصادقة؛ تم تسجيل خطأ تقني للتحقق.';
    }
    if (statusCode == 403) {
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'ليست لديك صلاحية لهذا الإجراء.';
    }
    if (statusCode == 404) {
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'العنصر المطلوب غير موجود.';
    }
    if (statusCode == 409) {
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'تعذر الإجراء بسبب تعارض في الحالة الحالية.';
    }
    if (statusCode == 422) {
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'راجع البيانات المدخلة وحاول مجددًا.';
    }
    return backendMessage.isNotEmpty
        ? backendMessage
        : 'حدث خطأ في الطلب ($statusCode).';
  }
}
