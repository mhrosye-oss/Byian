import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/quran/services/quran_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late QuranService service;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('itqan_quran_test_');
    Hive.init(hiveDirectory.path);
    service = QuranService();
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('loads the complete local Quran index and Al-Fatihah offline', () async {
    final surahs = await service.getSurahs();
    expect(surahs, hasLength(114));
    expect(surahs.first.nameArabic, 'الفاتحة');
    expect(surahs.first.ayahCount, 7);

    final ayahs = await service.getAyahs(1);
    expect(ayahs, hasLength(7));
    expect(ayahs.first.verseKey, '1:1');
    expect(ayahs.first.textUthmani, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
    expect(ayahs.last.verseKey, '1:7');
  });

  test('searches the entire Uthmani text without network access', () async {
    final results = await service.searchAyahs('الرحمن');
    expect(results, isNotEmpty);
    expect(results.any((ayah) => ayah.verseKey == '1:3'), isTrue);

    final harakatResults = await service.searchAyahs('الرَّحْمَٰن');
    expect(harakatResults.map((ayah) => ayah.verseKey),
        containsAll(results.map((ayah) => ayah.verseKey)));
  });

  test('builds the first and last Mushaf pages from local metadata', () async {
    final firstPage = await service.getPage(1);
    expect(firstPage.verses, isNotEmpty);
    expect(firstPage.verses.first.verseKey, '1:1');

    final lastPage = await service.getPage(604);
    expect(lastPage.verses, isNotEmpty);
    expect(lastPage.verses.first.verseKey, '112:1');
    expect(lastPage.verses.last.verseKey, '114:6');
  });

  test('validates invalid surah and page numbers', () async {
    await expectLater(service.getAyahs(115), throwsRangeError);
    await expectLater(service.getPage(605), throwsRangeError);
  });
}
