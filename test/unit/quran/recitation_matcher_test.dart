import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/quran_teacher/domain/services/recitation_matcher.dart';

void main() {
  const matcher = RecitationMatcher();

  group('RecitationMatcher.normalize', () {
    test('removes tashkeel and normalizes Arabic letter variants', () {
      expect(
        RecitationMatcher.normalize('أَكْرَامَة آمال إيمان'),
        'اكرامه امال ايمان',
      );
    });

    test('removes Quranic stop marks and punctuation', () {
      expect(
        RecitationMatcher.normalize('قُلْ هُوَ اللَّهُ أَحَدٌۢ،'),
        'قل هو الله احد',
      );
    });
  });

  group('RecitationMatcher.compare', () {
    test('marks exact and normalized matches correct', () {
      final result = matcher.compare(
        expectedText: 'أَنْعَمْتَ عَلَيْهِمْ',
        recognizedText: 'انعمت عليهم',
      );

      expect(result.accuracyPercent, 100);
      expect(result.words, hasLength(2));
      expect(result.words.every((word) => word.isCorrect), isTrue);
    });

    test('uses a strict greater-than-eighty-percent threshold', () {
      expect(matcher.similarity('مباركه', 'مبارك'), greaterThan(0.8));
      expect(matcher.similarity('سلام', 'س'), lessThanOrEqualTo(0.8));
    });

    test('aligns missing and extra words without shifting later matches', () {
      final result = matcher.compare(
        expectedText: 'بسم الله الرحمن الرحيم',
        recognizedText: 'بسم الرحمن الرحيم زيادة',
      );

      expect(result.accuracyPercent, 75);
      expect(
        result.words
            .where((word) => word.expectedWord == 'الله')
            .single
            .isCorrect,
        isFalse,
      );
      expect(
        result.words.where((word) => word.isExtra).single.recognizedWord,
        'زياده',
      );
      expect(result.words.last.recognizedWord, 'زياده');
    });

    test('returns zero for an empty recognized transcript', () {
      final result = matcher.compare(
        expectedText: 'الحمد لله',
        recognizedText: '',
      );
      expect(result.accuracyPercent, 0);
      expect(result.words.every((word) => !word.isCorrect), isTrue);
    });
  });
}
