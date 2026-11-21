import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/ayah.dart';
import 'arabic_normalizer.dart';

// ─── Page Data Models ────────────────────────────────────────────────────────

class PageWord {
  final String textUthmani;
  final String transliteration;
  final String translation;

  const PageWord({
    required this.textUthmani,
    required this.transliteration,
    required this.translation,
  });

  factory PageWord.fromJson(Map<String, dynamic> json) {
    return PageWord(
      textUthmani: json['text_uthmani'] as String? ?? '',
      transliteration: json['transliteration']?['text'] as String? ?? '',
      translation: json['translation']?['text'] as String? ?? '',
    );
  }
}

class VerseOnPage {
  final String verseKey;
  final int surahNumber;
  final int ayahNumber;
  final String textUthmani;
  final int juzNumber;
  final bool isFirstOfSurah;
  final List<PageWord> words;
  final String translation;

  const VerseOnPage({
    required this.verseKey,
    required this.surahNumber,
    required this.ayahNumber,
    required this.textUthmani,
    required this.juzNumber,
    required this.isFirstOfSurah,
    required this.words,
    required this.translation,
  });
}

class PageData {
  final int pageNumber;
  final int juzNumber;
  final int hizbNumber;
  final List<VerseOnPage> verses;

  const PageData({
    required this.pageNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required this.verses,
  });
}

// ─── QuranService ────────────────────────────────────────────────────────────

/// Provides the Tanzil Uthmani Quran and page layout from bundled local assets.
/// Optional translations, tafsir, Tajweed markup and timing APIs remain online.
class QuranService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const int ibnKathirArabicTafsirId = 14;
  static const Duration _qfCacheTtl = Duration(days: 7);
  static const String _quranTextAsset = 'assets/data/tanzil-quran-uthmani.txt';
  static const String _quranMetadataAsset =
      'assets/data/tanzil-quran-metadata.xml';
  static const String _timingsApiBaseUrl = String.fromEnvironment(
    'QURAN_TIMINGS_API_URL',
    defaultValue: '',
  );

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {
      'Accept': 'application/json',
      'User-Agent': 'Itqan Quran Reader',
    },
  ));

  late Box _cacheBox;
  Future<void>? _initialization;
  bool _initialized = false;
  List<Surah> _surahs = const [];
  Map<int, List<Ayah>> _ayahsBySurah = const {};
  List<({int index, int surah, int ayah})> _pageStarts = const [];
  List<({int index, int surah, int ayah})> _juzStarts = const [];
  List<({int index, int surah, int ayah})> _hizbQuarterStarts = const [];

  /// Loads and validates the complete local Quran before any screen needs it.
  /// Concurrent callers share the same initialization future.
  Future<void> init() async {
    if (_initialized) return;
    final pending = _initialization;
    if (pending != null) return pending;

    final task = _loadLocalData();
    _initialization = task;
    try {
      await task;
      _initialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _loadLocalData() async {
    if (!Hive.isBoxOpen('quran_cache')) {
      await Hive.openBox('quran_cache');
    }
    _cacheBox = Hive.box('quran_cache');

    final metadata = await rootBundle.loadString(_quranMetadataAsset);
    final surahs = _parseSurahs(metadata);
    final text = await rootBundle.loadString(_quranTextAsset);
    final ayahsBySurah = _parseAyahs(text);
    // Prefer the bundled Tanzil page, juz and hizb-quarter boundaries. Keep
    // deterministic fallbacks for alternate metadata assets that omit them.
    final parsedPageStarts = _parseMarkers(metadata, 'pages', 'page');
    final parsedJuzStarts = _parseMarkers(metadata, 'juzs', 'juz');
    final parsedHizbStarts = _parseMarkers(metadata, 'hizbs', 'quarter');
    final pageStarts = parsedPageStarts.isEmpty
        ? _buildUniformMarkers(surahs, 604)
        : parsedPageStarts;
    final juzStarts = parsedJuzStarts.isEmpty
        ? _buildUniformMarkers(surahs, 30)
        : parsedJuzStarts;
    final hizbStarts = parsedHizbStarts.isEmpty
        ? _buildUniformMarkers(surahs, 240)
        : parsedHizbStarts;

    final expectedVerseCount = surahs.fold<int>(
      0,
      (total, surah) => total + surah.ayahCount,
    );
    final actualVerseCount =
        ayahsBySurah.values.fold<int>(0, (total, list) => total + list.length);
    if (surahs.length != 114 ||
        expectedVerseCount != 6236 ||
        actualVerseCount != expectedVerseCount ||
        pageStarts.length != 604 ||
        juzStarts.length != 30 ||
        hizbStarts.length != 240) {
      throw FormatException(
        'Quran asset validation failed: ${surahs.length} surahs, '
        '$actualVerseCount verses, ${pageStarts.length} pages.',
      );
    }

    for (final surah in surahs) {
      final ayahs = ayahsBySurah[surah.number] ?? const <Ayah>[];
      if (ayahs.length != surah.ayahCount ||
          ayahs.indexed.any((entry) => entry.$1 + 1 != entry.$2.ayahNumber)) {
        throw FormatException(
          'Quran asset validation failed for surah ${surah.number}.',
        );
      }
    }

    _surahs = List.unmodifiable(surahs);
    _ayahsBySurah = Map.unmodifiable(ayahsBySurah.map(
      (number, ayahs) => MapEntry(number, List<Ayah>.unmodifiable(ayahs)),
    ));
    _pageStarts = List.unmodifiable(pageStarts);
    _juzStarts = List.unmodifiable(juzStarts);
    _hizbQuarterStarts = List.unmodifiable(hizbStarts);
  }

  List<({int index, int surah, int ayah})> _buildUniformMarkers(
    List<Surah> surahs,
    int count,
  ) {
    final totalVerses = surahs.fold<int>(
      0,
      (total, surah) => total + surah.ayahCount,
    );
    final markers = <({int index, int surah, int ayah})>[];
    for (var index = 0; index < count; index++) {
      var remaining = (index * totalVerses ~/ count) + 1;
      var surahNumber = surahs.last.number;
      for (final surah in surahs) {
        if (remaining <= surah.ayahCount) {
          surahNumber = surah.number;
          break;
        }
        remaining -= surah.ayahCount;
      }
      markers.add((index: index + 1, surah: surahNumber, ayah: remaining));
    }
    return markers;
  }

  List<({int index, int surah, int ayah})> _parseMarkers(
    String xml,
    String sectionName,
    String markerName,
  ) {
    final section = RegExp(
      '<$sectionName\\b[^>]*>([\\s\\S]*?)</$sectionName>',
    ).firstMatch(xml);
    if (section == null) return const [];
    final markers = <({int index, int surah, int ayah})>[];
    final markerPattern = RegExp('<$markerName\\b([^>]*)/?>');
    final attributePattern = RegExp(r'([A-Za-z_]+)="([^"]*)"');
    for (final tag in markerPattern.allMatches(section.group(1)!)) {
      final attributes = <String, String>{};
      for (final match in attributePattern.allMatches(tag.group(1)!)) {
        attributes[match.group(1)!] = match.group(2)!;
      }
      final index = int.tryParse(attributes['index'] ?? '');
      final surah = int.tryParse(attributes['sura'] ?? '');
      final ayah = int.tryParse(attributes['aya'] ?? '');
      if (index != null && surah != null && ayah != null) {
        markers.add((index: index, surah: surah, ayah: ayah));
      }
    }
    markers.sort((a, b) => a.index.compareTo(b.index));
    return markers;
  }

  List<Surah> _parseSurahs(String xml) {
    final surahTags = RegExp(r'<sura\b([^>]*)/?>').allMatches(xml);
    final attributePattern = RegExp(r'([A-Za-z_]+)="([^"]*)"');
    final surahs = <Surah>[];
    for (final tag in surahTags) {
      final attributes = <String, String>{};
      for (final match in attributePattern.allMatches(tag.group(1)!)) {
        attributes[match.group(1)!] = match.group(2)!;
      }
      final number = int.tryParse(attributes['index'] ?? '');
      final count = int.tryParse(attributes['ayas'] ?? '');
      if (number == null || count == null) continue;
      final revelationType = (attributes['type'] ?? '').toLowerCase();
      final revelationPlace = revelationType == 'meccan' ||
              revelationType == 'makkah'
          ? 'makkah'
          : revelationType == 'medinan' || revelationType == 'madinah'
              ? 'madinah'
              : revelationType;
      surahs.add(Surah(
        number: number,
        nameArabic: attributes['name'] ?? '',
        nameSimple: attributes['tname'] ?? '',
        nameTranslation: attributes['ename'] ?? '',
        ayahCount: count,
        revelationPlace: revelationPlace,
      ));
    }
    surahs.sort((a, b) => a.number.compareTo(b.number));
    return surahs;
  }

  Map<int, List<Ayah>> _parseAyahs(String text) {
    final result = <int, List<Ayah>>{};
    for (final line in const LineSplitter().convert(text)) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final firstSeparator = line.indexOf('|');
      final secondSeparator =
          firstSeparator < 0 ? -1 : line.indexOf('|', firstSeparator + 1);
      if (firstSeparator < 1 || secondSeparator < 0) {
        throw const FormatException('Malformed Tanzil Quran data line.');
      }
      final surahNumber = int.tryParse(line.substring(0, firstSeparator));
      final ayahNumber = int.tryParse(
        line.substring(firstSeparator + 1, secondSeparator),
      );
      final verseText = line.substring(secondSeparator + 1);
      if (surahNumber == null || ayahNumber == null || verseText.isEmpty) {
        throw const FormatException('Malformed Tanzil Quran verse.');
      }
      result.putIfAbsent(surahNumber, () => <Ayah>[]).add(Ayah(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            textUthmani: verseText,
            words: const [],
            translation: '',
          ));
    }
    for (final ayahs in result.values) {
      ayahs.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
    }
    return result;
  }

  /// Surah index and Arabic text are bundled and available offline.
  Future<List<Surah>> getSurahs() async {
    await init();
    return _surahs;
  }

  /// Uthmani verse text is bundled and available offline; translations are
  /// intentionally optional and must not block reading the Arabic text.
  Future<List<Ayah>> getAyahs(int surahNumber) async {
    await init();
    final ayahs = _ayahsBySurah[surahNumber];
    if (ayahs == null) {
      throw RangeError.range(surahNumber, 1, 114, 'surahNumber');
    }
    return ayahs;
  }

  /// Fetches a chosen translation separately so a network failure never blocks
  /// the local Arabic ayahs. Quran Foundation content is cached for seven days.
  Future<Map<int, String>> getTranslations(
    int surahNumber, {
    required int resourceId,
  }) async {
    await init();
    if (surahNumber < 1 || surahNumber > 114) {
      throw RangeError.range(surahNumber, 1, 114, 'surahNumber');
    }
    final cacheKey = 'translation_${resourceId}_$surahNumber';
    final cached = await _readApiCache(cacheKey);
    if (cached is Map) {
      return cached.map(
        (key, value) => MapEntry(int.parse(key.toString()), value.toString()),
      );
    }

    final response = await _dio.get(
      '/quran/translations/$resourceId',
      queryParameters: {
        'chapter_number': surahNumber,
        'fields': 'verse_key',
        'per_page': 300,
      },
    );
    final verses = response.data['translations'] as List<dynamic>? ?? const [];
    final result = <int, String>{};
    for (final verse in verses) {
      if (verse is! Map) continue;
      final data = Map<String, dynamic>.from(verse);
      final verseKey = data['verse_key'] as String? ?? '';
      final parts = verseKey.split(':');
      if (parts.length != 2 || int.tryParse(parts[0]) != surahNumber) continue;
      final ayahNumber = int.tryParse(parts[1]);
      final translation = _stripHtml(data['text'] as String? ?? '');
      if (ayahNumber != null && translation.isNotEmpty) {
        result[ayahNumber] = translation;
      }
    }
    await _writeApiCache(
      cacheKey,
      result.map((key, value) => MapEntry(key.toString(), value)),
    );
    return Map.unmodifiable(result);
  }

  /// Fetches translations keyed by verse_key for a Medina Mushaf page.
  Future<Map<String, String>> getPageTranslations(
    int pageNumber, {
    required int resourceId,
  }) async {
    await init();
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }
    final cacheKey = 'translation_${resourceId}_page_$pageNumber';
    final cached = await _readApiCache(cacheKey);
    if (cached is Map) {
      return cached.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    final response = await _dio.get(
      '/quran/translations/$resourceId',
      queryParameters: {
        'page_number': pageNumber,
        'fields': 'verse_key',
        'per_page': 100,
      },
    );
    final rows = response.data['translations'] as List<dynamic>? ?? const [];
    final result = <String, String>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final data = Map<String, dynamic>.from(row);
      final verseKey = data['verse_key'] as String?;
      final text = _stripHtml(data['text'] as String? ?? '');
      if (verseKey != null && text.isNotEmpty) result[verseKey] = text;
    }
    await _writeApiCache(cacheKey, result);
    return Map.unmodifiable(result);
  }

  /// Search the full bundled Quran locally after removing Arabic diacritics.
  Future<List<Ayah>> searchAyahs(String query, {int size = 50}) async {
    await init();
    if (size < 1) return const [];
    final normalizedQuery = ArabicNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final matches = <Ayah>[];
    for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
      for (final ayah in _ayahsBySurah[surahNumber]!) {
        if (ArabicNormalizer.normalize(ayah.textUthmani)
            .contains(normalizedQuery)) {
          matches.add(ayah);
          if (matches.length >= size) return List.unmodifiable(matches);
        }
      }
    }
    return List.unmodifiable(matches);
  }

  /// Builds a Medina Mushaf page from the bundled text and Tanzil metadata.
  /// Page layout remains available offline and does not rely on a network API.
  Future<PageData> getPage(int pageNumber) async {
    await init();
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }
    if (_pageStarts.length != 604) {
      return PageData(
          pageNumber: pageNumber, juzNumber: 0, hizbNumber: 0, verses: []);
    }
    final start = _pageStarts[pageNumber - 1];
    final firstOrdinal = _verseOrdinal(start.surah, start.ayah);
    final endOrdinal = pageNumber == 604
        ? 6237
        : _verseOrdinal(
            _pageStarts[pageNumber].surah,
            _pageStarts[pageNumber].ayah,
          );
    final juzNumber = _markerAt(_juzStarts, firstOrdinal)?.index ?? 0;
    final hizbQuarter = _markerAt(_hizbQuarterStarts, firstOrdinal)?.index ?? 0;
    int? previousSurah;
    final verseList = <VerseOnPage>[];
    for (var surahNumber = start.surah; surahNumber <= 114; surahNumber++) {
      for (final ayah in _ayahsBySurah[surahNumber]!) {
        final ordinal = _verseOrdinal(surahNumber, ayah.ayahNumber);
        if (ordinal < firstOrdinal) continue;
        if (ordinal >= endOrdinal) break;
        verseList.add(VerseOnPage(
          verseKey: ayah.verseKey,
          surahNumber: surahNumber,
          ayahNumber: ayah.ayahNumber,
          textUthmani: ayah.textUthmani,
          juzNumber: juzNumber,
          isFirstOfSurah: ayah.ayahNumber == 1,
          words: const [],
          translation: '',
        ));
        previousSurah = surahNumber;
      }
      if (previousSurah != null &&
          _verseOrdinal(surahNumber, _ayahsBySurah[surahNumber]!.length) >=
              endOrdinal - 1) {
        break;
      }
    }

    return PageData(
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      hizbNumber: (hizbQuarter + 3) ~/ 4,
      verses: verseList,
    );
  }

  int _verseOrdinal(int surahNumber, int ayahNumber) {
    var precedingVerses = 0;
    for (var number = 1; number < surahNumber; number++) {
      precedingVerses += _surahs[number - 1].ayahCount;
    }
    return precedingVerses + ayahNumber;
  }

  ({int index, int surah, int ayah})? _markerAt(
    List<({int index, int surah, int ayah})> markers,
    int ordinal,
  ) {
    ({int index, int surah, int ayah})? result;
    for (final marker in markers) {
      if (_verseOrdinal(marker.surah, marker.ayah) > ordinal) break;
      result = marker;
    }
    return result;
  }

  /// Fetches Quran Foundation's reviewed color-coded Uthmani Tajweed markup.
  /// Markup is optional (the local Quran remains readable offline) and follows
  /// the same seven-day cache limit as other Quran Foundation content.
  Future<Map<int, String>> getTajweedTexts(int surahNumber) async {
    await init();
    if (surahNumber < 1 || surahNumber > 114) {
      throw RangeError.range(surahNumber, 1, 114, 'surahNumber');
    }
    final cacheKey = 'tajweed_$surahNumber';
    final cached = await _readApiCache(cacheKey);
    if (cached is Map) {
      return cached.map(
        (key, value) => MapEntry(int.parse(key.toString()), value.toString()),
      );
    }

    final response = await _dio.get(
      '/quran/verses/uthmani_tajweed',
      queryParameters: {'chapter_number': surahNumber, 'per_page': 300},
    );
    final verses = response.data['verses'] as List<dynamic>? ?? const [];
    final result = <int, String>{};
    for (final verse in verses) {
      if (verse is! Map) continue;
      final data = Map<String, dynamic>.from(verse);
      final verseKey = data['verse_key'] as String? ?? '';
      final parts = verseKey.split(':');
      if (parts.length != 2 || int.tryParse(parts[0]) != surahNumber) continue;
      final ayahNumber = int.tryParse(parts[1]);
      final markup = data['text_uthmani_tajweed'] as String?;
      if (ayahNumber != null && markup != null && markup.isNotEmpty) {
        result[ayahNumber] = markup;
      }
    }
    if (result.isEmpty) {
      throw StateError('لم يرجع مصدر التجويد بيانات لهذه السورة.');
    }
    await _writeApiCache(
      cacheKey,
      result.map((key, value) => MapEntry(key.toString(), value)),
    );
    return Map.unmodifiable(result);
  }

  /// Fetches Arabic Tafsir Ibn Kathir from Quran.com API v4. API content is
  /// cached for at most seven days in accordance with Quran Foundation terms.
  Future<String> getTafsir(
    String verseKey, {
    int resourceId = ibnKathirArabicTafsirId,
  }) async {
    await init();
    final cacheKey = 'tafsir_${resourceId}_$verseKey';
    final cached = await _readCachedString(cacheKey);
    if (cached != null) return cached;

    final response = await _dio.get('/tafsirs/$resourceId/by_ayah/$verseKey');
    final raw = response.data['tafsir'];
    final html = raw is Map
        ? raw['text'] as String? ?? ''
        : raw is String
            ? raw
            : response.data['text'] as String? ?? '';
    final plainText = _stripHtml(html);
    if (plainText.isNotEmpty) await _writeApiCache(cacheKey, plainText);
    return plainText;
  }

  Future<String?> _readCachedString(String key) async {
    final value = await _readApiCache(key);
    return value is String ? value : null;
  }

  Future<dynamic> _readApiCache(String key) async {
    final entry = _cacheBox.get(key);
    if (entry is! Map) {
      if (entry != null) await _cacheBox.delete(key);
      return null;
    }
    final cachedAt = entry['cachedAt'] as int?;
    final encoded = entry['data'] as String?;
    if (cachedAt == null || encoded == null) {
      await _cacheBox.delete(key);
      return null;
    }
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(cachedAt),
    );
    if (age.isNegative || age > _qfCacheTtl) {
      await _cacheBox.delete(key);
      return null;
    }
    return jsonDecode(encoded);
  }

  Future<void> _writeApiCache(String key, dynamic value) async {
    await _cacheBox.put(key, {
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(value),
    });
  }

  /// Adds per-word timings returned by the application's secured backend.
  /// No API secret is embedded in this Flutter application.
  Future<Ayah> attachWordTimings(Ayah ayah) async {
    if (_timingsApiBaseUrl.trim().isEmpty) return ayah;

    final timingClient = Dio(BaseOptions(
      baseUrl: _timingsApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    final response = await timingClient.get(
      '/v1/verses/${ayah.verseKey}/word-timings',
      queryParameters: {'reciter': 'alafasy'},
    );
    final body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    final rows = body['words'] as List<dynamic>? ?? const [];
    if (rows.isEmpty) return ayah;

    final originalByPosition = {
      for (final word in ayah.words) word.position: word
    };
    final timedWords = <Word>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final data = Map<String, dynamic>.from(row);
      final position = (data['position'] as num?)?.toInt() ?? 0;
      final original = originalByPosition[position];
      final startMs = (data['start_ms'] as num?)?.toInt();
      final endMs = (data['end_ms'] as num?)?.toInt();
      if (original != null) {
        timedWords.add(original.copyWith(
          startMs: startMs,
          endMs: endMs,
          tajweedRule: data['tajweed_rule'] as String?,
        ));
      } else {
        timedWords.add(Word(
          position: position,
          textUthmani: data['text_uthmani'] as String? ?? '',
          transliteration: data['transliteration'] as String? ?? '',
          startMs: startMs,
          endMs: endMs,
          tajweedRule: data['tajweed_rule'] as String?,
        ));
      }
    }
    timedWords.sort((a, b) => a.position.compareTo(b.position));
    return ayah.copyWith(words: timedWords);
  }

  String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<sup\b[^>]*>.*?</sup>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
