import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../quran/services/arabic_normalizer.dart';

// Verified/manual annotations by verse and word. Key: surah:ayah:wordIndex.
const Map<String, String> tajweedAnnotations = {
  '1:1:0': 'bismillah',
  '1:1:2': 'madd',
  '1:1:3': 'ghunnah',
  '1:2:0': 'madd',
  '1:3:0': 'madd',
  '1:3:1': 'ghunnah',
  '1:4:0': 'madd',
  '1:5:0': 'idgham',
  '1:6:0': 'madd',
  '1:7:2': 'qalqalah',
  '112:1:0': 'madd',
  '112:2:0': 'idgham',
  '112:2:1': 'madd',
  '112:4:0': 'ghunnah',
};

/// Deprecated heuristic reference only. It is deliberately not used to color
/// Quran text because Tajweed depends on context, not isolated letter shapes.
const Map<String, String> tajweedCharacterRules = {
  'نّ': 'ghunnah',
  'مّ': 'ghunnah',
  'قْ': 'qalqalah',
  'طْ': 'qalqalah',
  'بْ': 'qalqalah',
  'جْ': 'qalqalah',
  'دْ': 'qalqalah',
  'آ': 'madd',
  'آ': 'madd',
  'وٓ': 'madd',
  'يٓ': 'madd',
};

Color tajweedColor(String rule) {
  return switch (rule) {
    'idgham' => ItqanColors.tajweedIdgham,
    'ikhfa' => ItqanColors.tajweedIkhfa,
    'iqlab' => ItqanColors.tajweedIqlab,
    'madd' => ItqanColors.tajweedMadd,
    'qalqalah' => ItqanColors.tajweedQalqalah,
    'ghunnah' => ItqanColors.tajweedGhunnah,
    'bismillah' => ItqanColors.roseGold,
    _ => ItqanColors.ink,
  };
}

String? tajweedRuleForCluster(String cluster) {
  for (final entry in tajweedCharacterRules.entries) {
    if (cluster.startsWith(entry.key)) return entry.value;
  }
  return null;
}

/// Verifies that tagged text represents the same ayah as the local text.
bool tajweedMarkupMatchesText(String markup, String localAyah) {
  final untagged = markup
      .replaceAll(RegExp(r'<tajweed[^>]*>|</tajweed>'), '')
      .replaceAll(RegExp(r'<span[^>]*>.*?</span>', dotAll: true), '')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
  return ArabicNormalizer.normalize(untagged) ==
      ArabicNormalizer.normalize(localAyah);
}

/// Parses Quran Foundation's documented `text_uthmani_tajweed` tags. Unknown
/// classes stay in the normal text color rather than being guessed.
TextSpan tajweedApiMarkupSpan(String markup, {double fontSize = 22}) {
  final baseStyle = TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: fontSize,
    height: 2,
    color: ItqanColors.ink,
  );
  final tokenPattern = RegExp(
    r'<tajweed\s+class="?([A-Za-z0-9_]+)"?>(.*?)</tajweed>|<span\s+class="?end"?>(.*?)</span>',
    dotAll: true,
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in tokenPattern.allMatches(markup)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: markup.substring(cursor, match.start)));
    }
    final className = match.group(1);
    if (className != null) {
      final color = _tajweedApiColor(className);
      spans.add(TextSpan(
        text: match.group(2) ?? '',
        style: color == null ? null : TextStyle(color: color),
      ));
    }
    // The API's end-of-ayah numeral is omitted because the reader renders its
    // own ayah number separately.
    cursor = match.end;
  }
  if (cursor < markup.length) {
    spans.add(TextSpan(text: markup.substring(cursor)));
  }
  return TextSpan(style: baseStyle, children: spans);
}

Color? _tajweedApiColor(String className) {
  if (className.startsWith('madda_')) return ItqanColors.tajweedMadd;
  if (className.startsWith('ikhafa')) return ItqanColors.tajweedIkhfa;
  if (className.startsWith('idgham')) return ItqanColors.tajweedIdgham;
  if (className.startsWith('qalqalah')) return ItqanColors.tajweedQalqalah;
  if (className.startsWith('iqlab')) return ItqanColors.tajweedIqlab;
  if (className.startsWith('ghunnah')) return ItqanColors.tajweedGhunnah;
  return null;
}

TextSpan tajweedCharacterSpan(
  String text, {
  String? wordRule,
  double fontSize = 22,
}) {
  final clusterPattern = RegExp(
    r'[\u0621-\u064A\u0671-\u06D3][\u064B-\u065F\u0670\u06D6-\u06ED]*|[^\u0621-\u06ED]',
  );
  final baseStyle = TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: fontSize,
    height: 2,
    color: ItqanColors.ink,
  );
  final spans = <InlineSpan>[];

  for (final match in clusterPattern.allMatches(text)) {
    final cluster = match.group(0)!;
    final rule = wordRule;
    spans.add(TextSpan(
      text: cluster,
      style: rule == null ? null : TextStyle(color: tajweedColor(rule)),
    ));
  }

  return TextSpan(style: baseStyle, children: spans);
}

String tajweedRuleName(String rule) {
  return switch (rule) {
    'idgham' => 'Idgham — إدغام',
    'ikhfa' => 'Ikhfa — إخفاء',
    'iqlab' => 'Iqlab — إقلاب',
    'madd' => 'Madd — مدّ',
    'qalqalah' => 'Qalqalah — قلقلة',
    'ghunnah' => 'Ghunnah — غنّة',
    'bismillah' => 'Basmalah — بسملة',
    _ => rule,
  };
}

String tajweedExplanation(String rule) {
  return switch (rule) {
    'idgham' => 'إدخال حرف ساكن في حرف متحرك بحيث يصيران حرفًا واحدًا مشددًا.',
    'ikhfa' => 'إخفاء النون الساكنة أو التنوين عند حروف الإخفاء مع بقاء الغنة.',
    'iqlab' => 'قلب النون الساكنة أو التنوين ميمًا مخفاة عند الباء.',
    'madd' => 'إطالة الصوت بحرف المد وفق سبب المد ومقداره.',
    'qalqalah' => 'اضطراب الصوت عند النطق بحروف القلقلة الساكنة.',
    'ghunnah' => 'صوت أغنّ يخرج من الخيشوم ومقداره في مواضع مشهورة حركتان.',
    'bismillah' => 'البسملة: بسم الله الرحمن الرحيم.',
    _ => '',
  };
}
