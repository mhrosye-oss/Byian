import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';

class GamificationApiException implements Exception {
  const GamificationApiException(this.statusCode, this.message, {this.code, this.retryAfter});
  final int statusCode; final String message; final String? code; final int? retryAfter;
  @override String toString() => message;
}

class GamificationApi {
  GamificationApi({http.Client? client, String? baseUrl}) : _client = client ?? http.Client(), _baseUrl = (baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://blueviolet-viper-439935.hostingersite.com')).replaceAll(RegExp(r'/$'), '');
  final http.Client _client; final String _baseUrl;
  Uri _uri(String path) => Uri.parse('$_baseUrl/api/v1/$path');

  Future<Map<String,dynamic>> get(String path) async => _send(() async => _client.get(_uri(path), headers: await _headers()));
  Future<Map<String,dynamic>> post(String path, Map<String,dynamic> body) async => _send(() async => _client.post(_uri(path),headers: await _headers(),body:jsonEncode(body)));
  Future<Map<String,String>> _headers() async { final token=await AuthService.getToken(); if(token==null || token.isEmpty) throw const GamificationApiException(401,'يلزم تسجيل الدخول.'); return {'Authorization':'Bearer $token','Accept':'application/json','Content-Type':'application/json'}; }
  Future<Map<String,dynamic>> _send(Future<http.Response> Function() request) async { late http.Response response; try {response=await request();} on GamificationApiException {rethrow;} catch(e){throw GamificationApiException(0,'تعذر الاتصال بالخادم: $e');} if(response.statusCode==401){await AuthService.logout();throw const GamificationApiException(401,'انتهت الجلسة. سجل الدخول مجدداً.');} Map<String,dynamic> decoded={}; try{final value=jsonDecode(response.body); if(value is Map) decoded=Map<String,dynamic>.from(value);}catch(_){} if(response.statusCode<200 || response.statusCode>=300){final error=decoded['error'] is Map ? Map<String,dynamic>.from(decoded['error']) : decoded; throw GamificationApiException(response.statusCode,'${error['message']??decoded['message']??'فشل الطلب (${response.statusCode})'}',code:error['code']?.toString(),retryAfter:error['retry_after'] is num ? (error['retry_after'] as num).toInt():null);} return decoded; }
}
