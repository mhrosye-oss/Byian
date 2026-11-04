class NormalizedArabic {
  const NormalizedArabic(this.value, this.sourceStarts, this.sourceEnds);

  final String value;
  final List<int> sourceStarts;
  final List<int> sourceEnds;
}

/// Removes Arabic vowel marks and normalizes common Alif variants only for
/// matching; it never changes the Quranic text shown to the reader.
class ArabicNormalizer {
  static final RegExp _marks =
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

  static NormalizedArabic mapToSource(String source) {
    final output = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    var utf16Offset = 0;

    for (final rune in source.runes) {
      final character = String.fromCharCode(rune);
      final start = utf16Offset;
      utf16Offset += character.length;
      if (_marks.hasMatch(character)) {
        if (ends.isNotEmpty) ends[ends.length - 1] = utf16Offset;
        continue;
      }
      output.write(_normalizeCharacter(character));
      starts.add(start);
      ends.add(utf16Offset);
    }

    return NormalizedArabic(output.toString(), starts, ends);
  }

  static String _normalizeCharacter(String character) => switch (character) {
        'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
        'ى' => 'ي',
        _ => character,
      };

  static String normalize(String text) => mapToSource(text).value.trim();

  /// Returns UTF-16 offsets into the original string for each match.
  static List<({int start, int end})> matches(String source, String query) {
    final mapped = mapToSource(source);
    final haystack = mapped.value.runes.toList(growable: false);
    final needle = normalize(query).runes.toList(growable: false);
    if (needle.isEmpty || needle.length > haystack.length) return const [];

    final results = <({int start, int end})>[];
    var index = 0;
    while (index <= haystack.length - needle.length) {
      var equal = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (haystack[index + offset] != needle[offset]) {
          equal = false;
          break;
        }
      }
      if (equal) {
        results.add((
          start: mapped.sourceStarts[index],
          end: mapped.sourceEnds[index + needle.length - 1],
        ));
        index += needle.length;
      } else {
        index++;
      }
    }
    return results;
  }
}
