import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SmartTasbihState {
  final int count;
  final int target;
  final DateTime updatedAt;
  const SmartTasbihState({required this.count, required this.target, required this.updatedAt});
  factory SmartTasbihState.initial() => SmartTasbihState(count: 0, target: 33, updatedAt: DateTime.now());
  Map<String, dynamic> toJson() => {'count': count, 'target': target, 'updatedAt': updatedAt.toIso8601String()};
  factory SmartTasbihState.fromJson(Map<String, dynamic> json) => SmartTasbihState(count: json['count'] as int? ?? 0, target: json['target'] as int? ?? 33, updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now());
}

class SmartTasbihService {
  static const String _key = 'smart_tasbih_state';
  static Future<SmartTasbihState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return SmartTasbihState.initial();
    try { return SmartTasbihState.fromJson(jsonDecode(raw)); } catch (_) { return SmartTasbihState.initial(); }
  }
  static Future<void> save(SmartTasbihState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
  static Future<int> increment() async {
    final state = await load();
    final nextCount = state.count + 1;
    await save(SmartTasbihState(count: nextCount, target: state.target, updatedAt: DateTime.now()));
    return nextCount;
  }
  static Future<void> reset() async {
    final state = await load();
    await save(SmartTasbihState(count: 0, target: state.target, updatedAt: DateTime.now()));
  }
}
