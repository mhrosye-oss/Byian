import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/services/auth_service.dart';
import 'models/circle.dart';
import 'models/circle_type.dart';
import 'models/circle_member.dart';
import 'models/circle_task.dart';
import 'models/circle_dashboard.dart';

class CirclesApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const CirclesApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => message;
}

List<Map<String, dynamic>> parseCircleUserSearchResponse(Object? response) {
  if (response is! Map || response['data'] is! List) {
    throw const FormatException('قائمة المستخدمين غير موجودة في رد البحث.');
  }
  final users = response['data'] as List;
  return users.map((user) {
    if (user is! Map) {
      throw const FormatException('بيانات المستخدم غير صالحة.');
    }
    final parsed = Map<String, dynamic>.from(user);
    final rawId = parsed['id'] ?? parsed['user_id'];
    final userId = rawId is int ? rawId : int.tryParse('$rawId');
    final serverName = parsed['name']?.toString().trim();
    final maskedEmail = parsed['email_masked']?.toString().trim();
    final email = parsed['email']?.toString().trim();
    final name = serverName?.isNotEmpty == true
        ? serverName!
        : maskedEmail?.isNotEmpty == true
            ? maskedEmail!
            : email?.isNotEmpty == true
                ? email!
                : 'مستخدم';
    if (userId == null) {
      throw const FormatException('معرف المستخدم غير موجود.');
    }
    return {...parsed, 'id': userId, 'name': name};
  }).toList(growable: false);
}

class CirclesApi {
  static const String defaultBaseUrl =
      'https://blueviolet-viper-439935.hostingersite.com/api/v1';

  final Dio dio;

  CirclesApi({Dio? dioClient, String? baseUrl})
      : dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl:
                    (baseUrl ?? defaultBaseUrl).replaceAll(RegExp(r'/$'), ''),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          final statusCode = error.response?.statusCode;
          final message = error.response?.data is Map
              ? error.response!.data['message']?.toString() ??
                  error.response!.data['error']?.toString() ??
                  ''
              : '';
          if (statusCode == 401) {
            AuthService.expireSession().catchError((error) {
              debugPrint(
                  'Failed to handle an expired circle API session: $error');
            });
          }
          if (statusCode == 401 && message == 'Unauthenticated') {
            debugPrint(
              'Circle API returned Unauthenticated; verify the request sent its bearer token.',
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  CirclesApiException _handleDioError(DioException e, String defaultMsg) {
    final status = e.response?.statusCode ?? 500;
    String message = defaultMsg;
    Map<String, dynamic>? validationErrors;

    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] != null) {
        message = data['message'].toString();
      } else if (data['error'] is Map && data['error']['message'] != null) {
        message = data['error']['message'].toString();
      } else if (data['error'] is String) {
        message = data['error'] as String;
      }

      if (data['errors'] is Map) {
        validationErrors = Map<String, dynamic>.from(data['errors'] as Map);
        final messages = <String>[];
        for (final value in validationErrors.values) {
          if (value is List) {
            messages.addAll(
              value
                  .map((item) => item.toString())
                  .where((item) => item.isNotEmpty),
            );
          } else if (value != null && value.toString().isNotEmpty) {
            messages.add(value.toString());
          }
        }
        if (messages.isNotEmpty) {
          message = messages.join('، ');
        }
      }
    }

    return CirclesApiException(
      statusCode: status,
      message: message,
      errors: validationErrors,
    );
  }

  /// GET /api/v1/circles
  /// (Fallback to /circles/my if 404)
  Future<List<Circle>> fetchMyCircles() async {
    try {
      Response response;
      try {
        response = await dio.get('/circles');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await dio.get('/circles/my');
        } else {
          rethrow;
        }
      }

      final rawData = response.data;
      final List list;
      if (rawData is Map && rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData is List) {
        list = rawData;
      } else {
        list = [];
      }

      return list
          .map(
              (item) => Circle.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب قائمة الدوائر');
    }
  }

  /// GET /api/v1/circles/types
  /// (Fallback to /circle-types if 404)
  Future<List<CircleType>> fetchCircleTypes() async {
    try {
      Response response;
      try {
        response = await dio.get('/circles/types');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await dio.get('/circle-types');
        } else {
          rethrow;
        }
      }

      final rawData = response.data;
      final List list;
      if (rawData is Map && rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData is List) {
        list = rawData;
      } else {
        list = [];
      }

      return list
          .map((item) =>
              CircleType.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب أنواع الدوائر');
    }
  }

  /// POST /api/v1/circles
  Future<Circle> createCircle({
    required String name,
    required CircleType type,
    String? description,
    String privacyMode = 'private',
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        if (type.id != null) 'type_id': type.id,
        'type': type.key,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'privacy_mode': privacyMode,
      };

      final response = await dio.post('/circles', data: payload);
      final rawData = response.data;
      Map<String, dynamic> circleMap = {};

      if (rawData is Map) {
        if (rawData['data'] is Map) {
          final d = rawData['data'] as Map<String, dynamic>;
          circleMap = d['circle'] is Map<String, dynamic>
              ? d['circle'] as Map<String, dynamic>
              : d;
        } else {
          circleMap = Map<String, dynamic>.from(rawData);
        }
      }

      return Circle.fromJson(circleMap);
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إنشاء الدائرة');
    }
  }

  /// POST /api/v1/invitations/redeem
  Future<Map<String, dynamic>> redeemInvitation(String code) async {
    try {
      final response = await dio.post('/invitations/redeem', data: {
        'code': code.trim(),
      });

      final rawData = response.data;
      if (rawData is Map && rawData['data'] is Map) {
        return Map<String, dynamic>.from(rawData['data'] as Map);
      }
      return rawData is Map ? Map<String, dynamic>.from(rawData) : {};
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 500;
      if (status == 404) {
        throw const CirclesApiException(
          statusCode: 404,
          message: 'كود الدعوة غير صحيح أو غير موجود',
        );
      } else if (status == 410) {
        throw const CirclesApiException(
          statusCode: 410,
          message: 'انتهت صلاحية كود الدعوة',
        );
      } else if (status == 409) {
        throw const CirclesApiException(
          statusCode: 409,
          message: 'أنت عضو بالفعل في هذه الدائرة',
        );
      }
      throw _handleDioError(e, 'فشل الانضمام للدائرة');
    }
  }

  /// GET /api/v1/me/invitations
  Future<List<Map<String, dynamic>>> fetchMyInvitations() async {
    try {
      final response = await dio.get('/me/invitations');
      final rawData = response.data;
      List list = [];
      if (rawData is Map) {
        if (rawData['data'] is List) {
          list = rawData['data'] as List;
        } else if (rawData['invitations'] is List) {
          list = rawData['invitations'] as List;
        }
      } else if (rawData is List) {
        list = rawData;
      }

      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب دعواتي');
    }
  }

  /// POST /api/v1/me/invitations/{uuid}/accept
  Future<void> acceptInvitation(String invitationUuid) async {
    try {
      await dio.post('/me/invitations/$invitationUuid/accept');
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل قبول الدعوة');
    }
  }

  /// POST /api/v1/me/invitations/{uuid}/decline
  Future<void> declineInvitation(String invitationUuid) async {
    try {
      await dio.post('/me/invitations/$invitationUuid/decline');
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل رفض الدعوة');
    }
  }

  /// GET /api/v1/circles/{uuid}/search-user?email=...
  /// The backend returns a list in `data`, not a single `user` object.
  Future<List<Map<String, dynamic>>> searchCircleUsers(
    String circleUuid, {
    required String email,
  }) async {
    try {
      final response = await dio.get(
        '/circles/$circleUuid/search-user',
        queryParameters: {'email': email.trim()},
      );
      return parseCircleUserSearchResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const CirclesApiException(
          statusCode: 403,
          message:
              'ليس لديك صلاحية البحث عن الأعضاء (يجب أن تكون مالكًا أو مشرفًا).',
        );
      }
      throw _handleDioError(e, 'تعذر البحث عن المستخدم بالبريد');
    } on FormatException catch (e) {
      throw CirclesApiException(
        statusCode: 502,
        message: 'تعذر قراءة نتيجة البحث: ${e.message}',
      );
    }
  }

  /// POST /api/v1/circles/{uuid}/direct-invitations
  Future<void> sendDirectInvitation({
    required String circleUuid,
    required int userId,
    String? message,
  }) async {
    try {
      await dio.post(
        '/circles/$circleUuid/direct-invitations',
        data: {
          'user_id': userId,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'تعذر إرسال الدعوة بالبريد');
    }
  }

  /// POST /api/v1/circles/{uuid}/invitations
  Future<Map<String, dynamic>> createInvitation(String circleUuid) async {
    try {
      final response = await dio.post('/circles/$circleUuid/invitations');
      final raw = response.data;
      final data = raw is Map ? raw['data'] : raw;
      if (data is Map && data['invitation'] is Map) {
        return Map<String, dynamic>.from(data['invitation'] as Map);
      }
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw _handleDioError(e, 'تعذر إنشاء رمز الدعوة');
    }
  }

  /// GET /api/v1/circles/{uuid}/dashboard
  Future<CircleDashboardData> fetchCircleDashboard(
    String circleUuid, {
    Circle? fallbackCircle,
  }) async {
    try {
      final response = await dio.get('/circles/$circleUuid/dashboard');
      final rawData = response.data;
      Map<String, dynamic> map = {};

      if (rawData is Map) {
        if (rawData['data'] is Map) {
          map = Map<String, dynamic>.from(rawData['data'] as Map);
        } else {
          map = Map<String, dynamic>.from(rawData);
        }
      }

      final currentUserId = await AuthService.getUserId();
      return CircleDashboardData.fromJson(
        map,
        fallbackCircle: fallbackCircle,
        currentUserId: currentUserId,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب بيانات لوحة الدائرة');
    }
  }

  /// GET /api/v1/circles/{uuid}/members
  Future<List<CircleMember>> fetchCircleMembers(String circleUuid) async {
    try {
      final response = await dio.get('/circles/$circleUuid/members');
      final rawData = response.data;
      final List list;

      if (rawData is Map && rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData is List) {
        list = rawData;
      } else {
        list = [];
      }

      return list
          .map((item) =>
              CircleMember.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب قائمة الأعضاء');
    }
  }

  /// GET /api/v1/circles/{uuid}/tasks
  Future<List<CircleTask>> fetchCircleTasks(String circleUuid) async {
    try {
      final response = await dio.get('/circles/$circleUuid/tasks');
      final currentUserId = await AuthService.getUserId();
      final rawData = response.data;
      final List list;

      if (rawData is Map && rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData is List) {
        list = rawData;
      } else {
        list = [];
      }

      return list
          .map((item) => CircleTask.fromJson(
                Map<String, dynamic>.from(item as Map),
                currentUserId: currentUserId,
              ))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب مهام الدائرة');
    }
  }

  /// POST /api/v1/circles/{uuid}/tasks
  Future<CircleTask> createTask({
    required String circleUuid,
    required String title,
    String? description,
    String taskType = 'custom',
    String priority = 'normal',
    List<int> assignedTo = const [],
    int? targetValue,
    String? targetUnit,
    DateTime? dueAt,
    bool isSecret = false,
  }) async {
    const allowedTaskTypes = {
      'quran',
      'adhkar',
      'dua',
      'custom',
      'tasbih',
      'counter',
    };
    if (!allowedTaskTypes.contains(taskType)) {
      throw ArgumentError.value(taskType, 'taskType', 'Unsupported task type');
    }

    try {
      final payload = <String, dynamic>{
        'title': title.trim(),
        'task_type': taskType,
        'priority': priority,
        'is_secret': isSecret,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'assigned_to': assignedTo,
        if (targetValue != null) 'target_value': targetValue,
        if (targetUnit != null && targetUnit.trim().isNotEmpty)
          'target_unit': targetUnit.trim(),
        if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
      };

      final response =
          await dio.post('/circles/$circleUuid/tasks', data: payload);
      final rawData = response.data;
      Map<String, dynamic> taskMap = {};

      if (rawData is Map) {
        if (rawData['data'] is Map) {
          final data = rawData['data'] as Map;
          if (data['task'] is Map) {
            taskMap = Map<String, dynamic>.from(data['task'] as Map);
          } else {
            taskMap = Map<String, dynamic>.from(data);
          }
        } else {
          taskMap = Map<String, dynamic>.from(rawData);
        }
      }

      return CircleTask.fromJson(taskMap);
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إنشاء المهمة');
    }
  }

  /// POST /api/v1/me/tasks/{uuid}/complete
  Future<bool> completeTask(
    String taskUuid, {
    String? notes,
    String? evidenceUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (evidenceUrl != null && evidenceUrl.trim().isNotEmpty)
          'evidence_url': evidenceUrl.trim(),
      };
      final response = await dio.post(
        '/me/tasks/$taskUuid/complete',
        data: payload.isEmpty ? null : payload,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 500;
      if (status == 409) {
        throw const CirclesApiException(
          statusCode: 409,
          message: 'المهمة مكتملة بالفعل',
        );
      } else if (status == 403) {
        throw const CirclesApiException(
          statusCode: 403,
          message: 'هذه المهمة غير مسندة إليك',
        );
      }
      throw _handleDioError(e, 'فشل إنجاز المهمة، حاول مرة أخرى');
    }
  }

  /// POST /api/v1/me/tasks/{uuid}/increment
  Future<Map<String, dynamic>> incrementTask(
    String taskUuid, {
    int amount = 1,
  }) async {
    if (amount < 1) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero');
    }
    try {
      final response = await dio.post(
        '/me/tasks/$taskUuid/increment',
        data: {'amount': amount},
      );
      final raw = response.data;
      if (raw is Map) {
        final data = raw['data'];
        return Map<String, dynamic>.from(data is Map ? data : raw);
      }
      return const {};
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل تحديث عداد المهمة');
    }
  }

  /// POST /api/v1/me/tasks/{uuid}/pass
  Future<void> passTask(String taskUuid, {required int nextUserId}) async {
    try {
      await dio.post(
        '/me/tasks/$taskUuid/pass',
        data: {'next_user_id': nextUserId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل تمرير سلسلة الخير');
    }
  }

  /// GET /api/v1/circles/{uuid}/khatmahs
  Future<List<Map<String, dynamic>>> fetchCircleKhatmahs(
    String circleUuid,
  ) async {
    try {
      final response = await dio.get('/circles/$circleUuid/khatmahs');
      final raw = response.data;
      final data = raw is Map ? raw['data'] : raw;
      final list = data is List
          ? data
          : data is Map && data['khatmahs'] is List
              ? data['khatmahs'] as List
              : <dynamic>[];
      return list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب الختمات الجماعية');
    }
  }

  /// POST /api/v1/circles/{uuid}/khatmahs
  Future<Map<String, dynamic>> createCircleKhatmah({
    required String circleUuid,
    required String title,
    String? description,
    DateTime? deadlineAt,
  }) async {
    try {
      final response = await dio.post(
        '/circles/$circleUuid/khatmahs',
        data: {
          'title': title.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (deadlineAt != null)
            'deadline_at':
                '${deadlineAt.year.toString().padLeft(4, '0')}-${deadlineAt.month.toString().padLeft(2, '0')}-${deadlineAt.day.toString().padLeft(2, '0')}',
        },
      );
      final raw = response.data;
      if (raw is Map && raw['data'] is Map) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      return raw is Map ? Map<String, dynamic>.from(raw) : {};
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إنشاء الختمة');
    }
  }

  /// GET /api/v1/khatmahs/{uuid}
  Future<Map<String, dynamic>> fetchKhatmah(String khatmahUuid) async {
    try {
      final response = await dio.get('/khatmahs/$khatmahUuid');
      final raw = response.data;
      final data = raw is Map ? raw['data'] : raw;
      if (data is Map && data['khatmah'] is Map) {
        return Map<String, dynamic>.from(data['khatmah'] as Map);
      }
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب تفاصيل الختمة');
    }
  }

  /// POST /api/v1/khatmah-assignments/{uuid}/complete
  Future<void> completeKhatmahAssignment(String assignmentUuid) async {
    try {
      await dio.post('/khatmah-assignments/$assignmentUuid/complete');
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل تسجيل إكمال الجزء');
    }
  }

  /// GET /api/v1/circles/{uuid}/dua-requests
  Future<List<Map<String, dynamic>>> fetchDuaRequests(
    String circleUuid,
  ) async {
    try {
      final response = await dio.get('/circles/$circleUuid/dua-requests');
      return _extractMapList(response.data, const ['dua_requests', 'requests']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب طلبات الدعاء');
    }
  }

  /// POST /api/v1/circles/{uuid}/dua-requests
  Future<void> createDuaRequest({
    required String circleUuid,
    required String requestText,
    bool isAnonymous = false,
    int? targetUserId,
  }) async {
    try {
      await dio.post(
        '/circles/$circleUuid/dua-requests',
        data: {
          'request_text': requestText.trim(),
          'is_anonymous': isAnonymous,
          if (targetUserId != null) 'target_user_id': targetUserId,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إرسال طلب الدعاء');
    }
  }

  /// POST /api/v1/dua-requests/{uuid}/pray
  Future<void> prayForRequest(String requestUuid) async {
    try {
      await dio.post('/dua-requests/$requestUuid/pray');
    } on DioException catch (e) {
      throw _handleDioError(e, 'تعذر تسجيل الدعاء');
    }
  }

  /// PATCH /api/v1/dua-requests/{uuid}/mark-answered
  Future<void> markDuaAnswered(String requestUuid) async {
    try {
      await dio.patch('/dua-requests/$requestUuid/mark-answered');
    } on DioException catch (e) {
      throw _handleDioError(e, 'تعذر تحديث حالة طلب الدعاء');
    }
  }

  /// GET /api/v1/circles/{uuid}/daily-questions/today
  Future<Map<String, dynamic>?> fetchTodayQuestion(String circleUuid) async {
    try {
      final response =
          await dio.get('/circles/$circleUuid/daily-questions/today');
      final raw = response.data;
      final data = raw is Map ? raw['data'] : raw;
      if (data is Map && data['question'] is Map) {
        return Map<String, dynamic>.from(data['question'] as Map);
      }
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e, 'فشل جلب سؤال اليوم');
    }
  }

  /// POST /api/v1/circles/{uuid}/daily-questions
  Future<void> createDailyQuestion({
    required String circleUuid,
    required String question,
    required List<String> options,
    required int correctIndex,
    String? category,
    String? explanation,
    DateTime? questionDate,
  }) async {
    try {
      await dio.post(
        '/circles/$circleUuid/daily-questions',
        data: {
          'question': question.trim(),
          'options': options,
          'correct_index': correctIndex,
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          if (explanation != null && explanation.trim().isNotEmpty)
            'explanation': explanation.trim(),
          if (questionDate != null)
            'question_date': questionDate.toIso8601String().split('T').first,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إنشاء سؤال اليوم');
    }
  }

  /// POST /api/v1/daily-questions/{uuid}/answer
  Future<Map<String, dynamic>> answerDailyQuestion({
    required String questionUuid,
    required int chosenIndex,
  }) async {
    try {
      final response = await dio.post(
        '/daily-questions/$questionUuid/answer',
        data: {'chosen_index': chosenIndex},
      );
      final raw = response.data;
      final data = raw is Map ? raw['data'] : raw;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إرسال إجابة السؤال');
    }
  }

  /// GET /api/v1/circles/{uuid}/study-sessions
  Future<List<Map<String, dynamic>>> fetchStudySessions(
    String circleUuid,
  ) async {
    try {
      final response = await dio.get('/circles/$circleUuid/study-sessions');
      return _extractMapList(
          response.data, const ['study_sessions', 'sessions']);
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل جلب جلسات الدراسة');
    }
  }

  /// POST /api/v1/circles/{uuid}/study-sessions
  Future<void> createStudySession({
    required String circleUuid,
    required String title,
    String? description,
    int durationMinutes = 25,
    DateTime? startsAt,
  }) async {
    try {
      await dio.post(
        '/circles/$circleUuid/study-sessions',
        data: {
          'title': title.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'duration_minutes': durationMinutes,
          if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل إنشاء جلسة الدراسة');
    }
  }

  /// POST /api/v1/study-sessions/{uuid}/join
  Future<void> joinStudySession(String sessionUuid) async {
    try {
      await dio.post('/study-sessions/$sessionUuid/join');
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل الانضمام لجلسة الدراسة');
    }
  }

  /// POST /api/v1/study-sessions/{uuid}/leave
  Future<void> leaveStudySession(String sessionUuid) async {
    try {
      await dio.post('/study-sessions/$sessionUuid/leave');
    } on DioException catch (e) {
      throw _handleDioError(e, 'فشل مغادرة جلسة الدراسة');
    }
  }

  List<Map<String, dynamic>> _extractMapList(
    dynamic response,
    List<String> possibleKeys,
  ) {
    final data = response is Map ? response['data'] : response;
    final list = data is List
        ? data
        : data is Map
            ? possibleKeys.map((key) => data[key]).whereType<List>().firstOrNull
            : null;
    return (list ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// POST /api/v1/circles/{uuid}/leave
  Future<bool> leaveCircle(String circleUuid) async {
    try {
      final response = await dio.post('/circles/$circleUuid/leave');
      return response.statusCode == 200;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 500;
      if (status == 409 || status == 400) {
        throw const CirclesApiException(
          statusCode: 409,
          message: 'لا يمكنك مغادرة الدائرة كمالك وحيد',
        );
      }
      throw _handleDioError(e, 'فشل مغادرة الدائرة');
    }
  }

  /// Collects assigned tasks via GET /api/v1/circles/{uuid}/tasks.
  Future<List<CircleTask>> fetchMyTasks() async {
    final currentUserId = await AuthService.getUserId();
    if (currentUserId == null) return const [];

    final circles = await fetchMyCircles();
    final tasksByCircle = await Future.wait(
      circles.map((circle) => fetchCircleTasks(circle.uuid)),
    );
    return tasksByCircle
        .expand((tasks) => tasks)
        .where((task) => task.assignedToUserId == currentUserId)
        .toList();
  }
}
