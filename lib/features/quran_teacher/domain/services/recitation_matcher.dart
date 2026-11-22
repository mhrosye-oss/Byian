/// Word-level alignment for approximate Quran recitation feedback.
///
/// This is a text similarity aid, not a tajweed or pronunciation assessment.
class RecitationMatcher {
  const RecitationMatcher();

  static final RegExp _arabicMarks = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  static final RegExp _nonWordCharacters = RegExp(
    r'[^\p{L}\p{N}]+',
    unicode: true,
  );
  static final RegExp _spaces = RegExp(r'\s+');

  /// Removes tashkeel, normalizes common Arabic letter variants and spacing.
  static String normalize(String text) {
    final withoutMarks = text.replaceAll(_arabicMarks, '');
    final normalizedLetters = withoutMarks
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    return normalizedLetters
        .replaceAll(_nonWordCharacters, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  RecitationComparison compare({
    required String expectedText,
    required String recognizedText,
  }) {
    final expected =
        normalize(expectedText).split(' ').where((w) => w.isNotEmpty).toList();
    final spoken = normalize(recognizedText)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (expected.isEmpty) {
      return const RecitationComparison(words: [], accuracyPercent: 0);
    }

    final costs = List.generate(
      expected.length + 1,
      (_) => List<double>.filled(spoken.length + 1, 0),
    );
    for (var i = 1; i <= expected.length; i++) {
      costs[i][0] = i.toDouble();
    }
    for (var j = 1; j <= spoken.length; j++) {
      costs[0][j] = j.toDouble();
    }

    for (var i = 1; i <= expected.length; i++) {
      for (var j = 1; j <= spoken.length; j++) {
        final wordSimilarity = similarity(expected[i - 1], spoken[j - 1]);
        final substitution = wordSimilarity > 0.8 ? 0.0 : 1.0;
        final replace = costs[i - 1][j - 1] + substitution;
        final remove = costs[i - 1][j] + 1;
        final insert = costs[i][j - 1] + 1;
        costs[i][j] = _min3(replace, remove, insert);
      }
    }

    final aligned = <RecitationWordMatch>[];
    var i = expected.length;
    var j = spoken.length;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final score = similarity(expected[i - 1], spoken[j - 1]);
        final substitution = score > 0.8 ? 0.0 : 1.0;
        final candidate = costs[i - 1][j - 1] + substitution;
        if (score > 0.8 && (costs[i][j] - candidate).abs() < 0.000001) {
          aligned.add(
            RecitationWordMatch(
              expectedWord: expected[i - 1],
              recognizedWord: spoken[j - 1],
              similarity: score,
              isCorrect: score > 0.8,
            ),
          );
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 &&
          (j == 0 || (costs[i][j] - (costs[i - 1][j] + 1)).abs() < 0.000001)) {
        aligned.add(
          RecitationWordMatch(
            expectedWord: expected[i - 1],
            recognizedWord: null,
            similarity: 0,
            isCorrect: false,
          ),
        );
        i--;
      } else if (j > 0 &&
          (i == 0 || (costs[i][j] - (costs[i][j - 1] + 1)).abs() < 0.000001)) {
        aligned.add(
          RecitationWordMatch(
            expectedWord: null,
            recognizedWord: spoken[j - 1],
            similarity: 0,
            isCorrect: false,
            isExtra: true,
          ),
        );
        j--;
      } else if (i > 0 && j > 0) {
        final score = similarity(expected[i - 1], spoken[j - 1]);
        aligned.add(
          RecitationWordMatch(
            expectedWord: expected[i - 1],
            recognizedWord: spoken[j - 1],
            similarity: score,
            isCorrect: score > 0.8,
          ),
        );
        i--;
        j--;
      }
    }

    final words = aligned.reversed.toList(growable: false);
    final correctCount = words
        .where((word) => word.expectedWord != null && word.isCorrect)
        .length;
    return RecitationComparison(
      words: words,
      accuracyPercent: correctCount * 100 / expected.length,
    );
  }

  /// Character-level Levenshtein similarity in the inclusive range [0, 1].
  double similarity(String first, String second) {
    if (first == second) return 1;
    if (first.isEmpty || second.isEmpty) return 0;
    final a = first.runes.toList(growable: false);
    final b = second.runes.toList(growable: false);
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        current[j] = _min3(
          substitution.toDouble(),
          deletion.toDouble(),
          insertion.toDouble(),
        ).round();
      }
      previous = current;
    }
    final distance = previous[b.length];
    return 1 - distance / (a.length > b.length ? a.length : b.length);
  }

  double _min3(double first, double second, double third) => first < second
      ? (first < third ? first : third)
      : (second < third ? second : third);
}

class RecitationWordMatch {
  const RecitationWordMatch({
    required this.expectedWord,
    required this.recognizedWord,
    required this.similarity,
    required this.isCorrect,
    this.isExtra = false,
  });

  final String? expectedWord;
  final String? recognizedWord;
  final double similarity;
  final bool isCorrect;
  final bool isExtra;
}

class RecitationComparison {
  const RecitationComparison({
    required this.words,
    required this.accuracyPercent,
  });

  final List<RecitationWordMatch> words;
  final double accuracyPercent;
}
