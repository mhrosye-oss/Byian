import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/quran/services/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer', () {
    test('ignores tashkeel and Quranic elongation marks', () {
      expect(ArabicNormalizer.normalize('الرَّحْمَٰنُ'), 'الرحمن');
      expect(ArabicNormalizer.normalize('ٱللَّهِ'), 'الله');
    });

    test('normalizes common Alif variants for comparison', () {
      expect(ArabicNormalizer.normalize('إِيَّاكَ'), 'اياك');
      expect(ArabicNormalizer.normalize('ٱلرَّحْمَٰنِ'), 'الرحمن');
    });

    test('returns source offsets including marks attached to matched letters', () {
      const source = 'قُلْ هُوَ ٱللَّهُ أَحَدٌ';
      final ranges = ArabicNormalizer.matches(source, 'الله');
      expect(ranges, hasLength(1));
      expect(source.substring(ranges.single.start, ranges.single.end), 'ٱللَّهُ');
    });

    test('empty query has no matches', () {
      expect(ArabicNormalizer.matches('القرآن الكريم', '  '), isEmpty);
    });
  });
}
