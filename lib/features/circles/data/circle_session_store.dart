import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/circle_models.dart';

abstract interface class CircleSessionStore {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> saveUser(AppUser user);
  Future<AppUser?> readUser();
  Future<void> clear();
}

class SecureCircleSessionStore implements CircleSessionStore {
  SecureCircleSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const tokenKey = 'auth_token';
  static const userKey = 'circles_user';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: tokenKey);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: tokenKey, value: token);

  @override
  Future<void> saveUser(AppUser user) => _storage.write(
        key: userKey,
        value: jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'total_xp': user.totalXp,
          'total_coins': user.totalCoins,
          'level': user.level,
          'level_title': user.levelTitle,
        }),
      );

  @override
  Future<AppUser?> readUser() async {
    final raw = await _storage.read(key: userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      await _storage.delete(key: userKey);
    }
    return null;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userKey);
  }
}
