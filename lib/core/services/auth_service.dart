import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores authentication secrets separately from non-sensitive profile labels.
class AuthService {
  static const String _keyName = 'user_name';
  static const String _keyEmail = 'user_email';
  static const String _keyId = 'user_id';
  static const String _keySavedEmail = 'saved_email';
  static const String _legacySavedPass = 'saved_pass';
  static const String _savedPassKey = 'saved_pass_secure';
  static const String _tokenKey = 'itqan_bearer_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> saveSession({
    required String name,
    required String email,
    required String token,
    int? userId,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    if (userId != null) await prefs.setInt(_keyId, userId);
    if (userId == null) await prefs.remove(_keyId);
  }

  static Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

  static Future<void> clearToken() => _secureStorage.delete(key: _tokenKey);

  static Future<void> saveUser(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
  }

  static Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final email = prefs.getString(_keyEmail);
    if (name != null && email != null) return {'name': name, 'email': email};
    return null;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyId);
  }

  static Future<void> logout() async {
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyId);
  }

  static Future<void> saveCredentials(String email, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedEmail, email);
    await _secureStorage.write(key: _savedPassKey, value: pass);
    await prefs.remove(_legacySavedPass);
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keySavedEmail);
    var pass = await _secureStorage.read(key: _savedPassKey);
    if (pass == null) {
      // Migrate credentials saved by older app versions out of plaintext storage.
      pass = prefs.getString(_legacySavedPass);
      if (pass != null) {
        await _secureStorage.write(key: _savedPassKey, value: pass);
        await prefs.remove(_legacySavedPass);
      }
    }
    if (email != null && pass != null) return {'email': email, 'pass': pass};
    return null;
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedEmail);
    await prefs.remove(_legacySavedPass);
    await _secureStorage.delete(key: _savedPassKey);
  }
}
