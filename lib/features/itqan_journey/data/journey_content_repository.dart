import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../quran/models/ayah.dart';
import '../../quran/services/quran_service.dart';

/// Feature-owned progress repository reusing only the project's verified
/// Tanzil-backed QuranService. The Quran source assets remain unchanged.
class JourneyQuranRepository {
  JourneyQuranRepository({QuranService? service})
    : _service = service ?? QuranService();
  final QuranService _service;
  static const _boxName = 'itqan_journey_quran';
  static const _completedPagesKey = 'backend_confirmed_pages';
  static const _pendingPagesKey = 'pending_page_activities';

  Future<List<Surah>> surahs() => _service.getSurahs();
  Future<List<Ayah>> ayahs(int surah) => _service.getAyahs(surah);
  Future<int> lastSurah() async =>
      (await _box()).get('last_surah', defaultValue: 1) as int;
  Future<int> lastAyah() async =>
      (await _box()).get('last_ayah', defaultValue: 1) as int;
  Future<void> savePosition(int surah, int ayah) async {
    final box = await _box();
    await box.put('last_surah', surah);
    await box.put('last_ayah', ayah);
  }

  Future<Set<int>> completedPages() async {
    final raw = (await _box()).get(_completedPagesKey, defaultValue: const []);
    if (raw is! List) return {};
    return raw
        .whereType<num>()
        .map((page) => page.toInt())
        .where((page) => page >= 1 && page <= 604)
        .toSet();
  }

  Future<Map<int, String>> pendingPages() async {
    final raw = (await _box()).get(_pendingPagesKey);
    if (raw is! Map) return {};
    final result = <int, String>{};
    for (final entry in raw.entries) {
      final page = int.tryParse('${entry.key}');
      if (page == null || page < 1 || page > 604) continue;
      result[page] = '${entry.value}';
    }
    return result;
  }

  Future<void> markPagePending(int page, String idempotencyKey) async {
    if (page < 1 || page > 604 || idempotencyKey.isEmpty) return;
    final box = await _box();
    if ((await completedPages()).contains(page)) return;
    final pending = await pendingPages();
    pending[page] = idempotencyKey;
    await box.put(_pendingPagesKey, {
      for (final entry in pending.entries) '${entry.key}': entry.value,
    });
  }

  Future<void> markPageCompleted(int page) async {
    if (page < 1 || page > 604) return;
    final box = await _box();
    final pages = await completedPages();
    pages.add(page);
    final pending = await pendingPages();
    pending.remove(page);
    await box.put(_completedPagesKey, pages.toList()..sort());
    await box.put(_pendingPagesKey, {
      for (final entry in pending.entries) '${entry.key}': entry.value,
    });
  }

  Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
    return Hive.box(_boxName);
  }
}

class JourneyContentRepository {
  Future<List<Map<String, dynamic>>> loadDuas() async {
    final raw = await rootBundle.loadString('assets/data/duas_data.json');
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> loadAdhkar(String category) async {
    final raw = await rootBundle.loadString('assets/data/adhkar_data.json');
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return ((data[category] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
