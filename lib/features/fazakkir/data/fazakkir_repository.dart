import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/fazakkir_program.dart';
import '../domain/models/interaction_record.dart';
import '../domain/models/quiet_hours.dart';
import '../domain/models/reminder_item.dart';
import '../domain/models/smart_suggestion.dart';
import 'templates/fazakkir_templates.dart';

/// مستودع التخزين المحلي لخدمة «فَذَكِّر» (يعمل 100% دون إنترنت)
class FazakkirRepository {
  static const String _programsKey = 'fazakkir_programs_v1';
  static const String _remindersKey = 'fazakkir_reminders_v1';
  static const String _recordsKey = 'fazakkir_records_v1';
  static const String _quietHoursKey = 'fazakkir_quiet_hours_v1';
  static const String _suggestionsKey = 'fazakkir_suggestions_v1';
  static const String _maxDensityKey = 'fazakkir_max_density_v1';
  static const String _isInitializedKey = 'fazakkir_is_initialized_v1';
  static const String _lastRebuildKey = 'fazakkir_last_rebuild_v1';

  FazakkirRepository._();
  static final FazakkirRepository instance = FazakkirRepository._();

  /// تهيئة أولية: تفعيل قالبين افتراضيين عند أول تشغيل لخدمة فَذَكِّر
  Future<void> ensureInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final isInit = prefs.getBool(_isInitializedKey) ?? false;
    if (!isInit) {
      // تثبيت القالب الأول «يومٌ ذاكر» كبرنامج نشط افتراضي هادئ
      final templates = FazakkirTemplates.getTemplates();
      final defaultTemplate = templates.first;
      await saveProgram(defaultTemplate.program);
      for (final rem in defaultTemplate.reminders) {
        await saveReminder(rem);
      }
      await prefs.setBool(_isInitializedKey, true);
    }
  }

  // ─── Programs ─────────────────────────────────────────────────────────────

  Future<List<FazakkirProgram>> getPrograms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_programsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FazakkirProgram.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProgram(FazakkirProgram program) async {
    final programs = await getPrograms();
    final index = programs.indexWhere((p) => p.id == program.id);
    if (index >= 0) {
      programs[index] = program;
    } else {
      programs.add(program);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _programsKey,
      jsonEncode(programs.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> deleteProgram(String programId,
      {bool deleteAssociatedReminders = false}) async {
    final programs = await getPrograms();
    programs.removeWhere((p) => p.id == programId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _programsKey,
      jsonEncode(programs.map((p) => p.toJson()).toList()),
    );

    if (deleteAssociatedReminders) {
      final reminders = await getReminders();
      reminders.removeWhere((r) => r.programId == programId);
      await prefs.setString(
        _remindersKey,
        jsonEncode(reminders.map((r) => r.toJson()).toList()),
      );
    } else {
      // الإبقاء على التذكيرات مع فصلها عن البرنامج
      final reminders = await getReminders();
      final updated = reminders.map((r) {
        if (r.programId == programId) {
          return r.copyWith(programId: null);
        }
        return r;
      }).toList();
      await prefs.setString(
        _remindersKey,
        jsonEncode(updated.map((r) => r.toJson()).toList()),
      );
    }
  }

  // ─── Reminders ────────────────────────────────────────────────────────────

  Future<List<ReminderItem>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ReminderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReminder(ReminderItem reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      reminders[index] = reminder;
    } else {
      reminders.add(reminder);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _remindersKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == reminderId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _remindersKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );

    // إزالة المعرف من البرامج المرتبطة
    final programs = await getPrograms();
    final updatedPrograms = programs.map((p) {
      if (p.reminderIds.contains(reminderId)) {
        final newIds = List<String>.from(p.reminderIds)..remove(reminderId);
        return p.copyWith(reminderIds: newIds);
      }
      return p;
    }).toList();
    await prefs.setString(
      _programsKey,
      jsonEncode(updatedPrograms.map((p) => p.toJson()).toList()),
    );
  }

  // ─── Quiet Hours ──────────────────────────────────────────────────────────

  Future<QuietHoursSettings> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quietHoursKey);
    if (raw == null || raw.isEmpty) return const QuietHoursSettings();
    try {
      return QuietHoursSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return const QuietHoursSettings();
    }
  }

  Future<void> saveQuietHours(QuietHoursSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quietHoursKey, jsonEncode(settings.toJson()));
  }

  // ─── Interaction Records ──────────────────────────────────────────────────

  Future<List<InteractionRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => InteractionRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecord(InteractionRecord record) async {
    final records = await getRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    // الاحتفاظ بآخر 100 سجل لمنع تضخم الذاكرة
    if (records.length > 100) {
      records.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      records.removeRange(100, records.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  // ─── Smart Suggestions ───────────────────────────────────────────────────

  Future<List<SmartSuggestion>> getSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_suggestionsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SmartSuggestion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSuggestions(List<SmartSuggestion> suggestions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _suggestionsKey,
      jsonEncode(suggestions.map((s) => s.toJson()).toList()),
    );
  }

  // ─── Settings & Rebuild Metadata ──────────────────────────────────────────

  Future<int> getMaxDailyDensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxDensityKey) ?? 8;
  }

  Future<void> setMaxDailyDensity(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxDensityKey, count);
  }

  Future<DateTime?> getLastRebuildTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastRebuildKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> setLastRebuildTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRebuildKey, time.toIso8601String());
  }
}
