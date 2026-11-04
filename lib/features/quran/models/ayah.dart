class Word {
  final int position;
  final String textUthmani;
  final String transliteration;
  final int? startMs;
  final int? endMs;
  final String? tajweedRule;

  const Word({
    required this.position,
    required this.textUthmani,
    required this.transliteration,
    this.startMs,
    this.endMs,
    this.tajweedRule,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    final start = json['start_ms'] ?? json['timestamp_from'];
    final end = json['end_ms'] ?? json['timestamp_to'];
    return Word(
      position: json['position'] as int? ?? 0,
      textUthmani: json['text_uthmani'] as String? ?? '',
      transliteration: json['transliteration']?['text'] as String? ?? '',
      startMs: start is num ? start.round() : null,
      endMs: end is num ? end.round() : null,
      tajweedRule: json['tajweed_rule'] as String?,
    );
  }

  Word copyWith({int? startMs, int? endMs, String? tajweedRule}) => Word(
        position: position,
        textUthmani: textUthmani,
        transliteration: transliteration,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        tajweedRule: tajweedRule ?? this.tajweedRule,
      );
}

class Ayah {
  final int surahNumber;
  final int ayahNumber;
  final String textUthmani;
  final List<Word> words;
  final String translation;

  const Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.textUthmani,
    required this.words,
    required this.translation,
  });

  String get verseKey => '$surahNumber:$ayahNumber';

  Ayah copyWith({List<Word>? words}) => Ayah(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        textUthmani: textUthmani,
        words: words ?? this.words,
        translation: translation,
      );

  factory Ayah.fromJson(Map<String, dynamic> json) {
    final words = (json['words'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((word) => Word.fromJson(Map<String, dynamic>.from(word)))
        .toList(growable: false);

    String translation = '';
    final translations = json['translations'] as List<dynamic>?;
    if (translations != null && translations.isNotEmpty) {
      translation = translations.first['text'] as String? ?? '';
      translation = translation.replaceAll(RegExp(r'<[^>]*>'), '');
    }

    final verseKey = json['verse_key'] as String?;
    final keyParts = verseKey?.split(':') ?? const <String>[];
    return Ayah(
      surahNumber: json['chapter_id'] as int? ??
          (keyParts.isNotEmpty ? int.tryParse(keyParts[0]) : null) ??
          0,
      ayahNumber: json['verse_number'] as int? ??
          (keyParts.length > 1 ? int.tryParse(keyParts[1]) : null) ??
          0,
      textUthmani: json['text_uthmani'] as String? ??
          json['text'] as String? ??
          '',
      words: words,
      translation: translation,
    );
  }

  String get audioUrl {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final ayahPadded = ayahNumber.toString().padLeft(3, '0');
    return 'https://verses.quran.com/Alafasy/mp3/$surahPadded$ayahPadded.mp3';
  }

  Map<String, dynamic> toJson() => {
        'chapter_id': surahNumber,
        'verse_number': ayahNumber,
        'verse_key': verseKey,
        'text_uthmani': textUthmani,
        'words': words
            .map((word) => {
                  'position': word.position,
                  'text_uthmani': word.textUthmani,
                  'transliteration': {'text': word.transliteration},
                  if (word.startMs != null) 'start_ms': word.startMs,
                  if (word.endMs != null) 'end_ms': word.endMs,
                  if (word.tajweedRule != null)
                    'tajweed_rule': word.tajweedRule,
                })
            .toList(growable: false),
        'translations': [
          {'text': translation}
        ],
      };
}

class Surah {
  final int number;
  final String nameArabic;
  final String nameSimple;
  final String nameTranslation;
  final int ayahCount;
  final String revelationPlace;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameSimple,
    required this.nameTranslation,
    required this.ayahCount,
    required this.revelationPlace,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['id'] as int? ?? 0,
        nameArabic: json['name_arabic'] as String? ?? '',
        nameSimple: json['name_simple'] as String? ?? '',
        nameTranslation: json['translated_name']?['name'] as String? ?? '',
        ayahCount: json['verses_count'] as int? ?? 0,
        revelationPlace: json['revelation_place'] as String? ?? '',
      );
}
