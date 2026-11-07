import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../quran/screens/quran_search_screen.dart';
import '../quran/services/quran_service.dart';
import '../recitation/recitation_screen.dart';
import '../tajweed/tajweed_data.dart';
import '../settings/settings_service.dart';

final quranServiceProvider = Provider((ref) => QuranService());

final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getSurahs();
});

final ayahsProvider =
    FutureProvider.family<List<Ayah>, int>((ref, surahNumber) async {
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getAyahs(surahNumber);
});

final tajweedTextsProvider =
    FutureProvider.family<Map<int, String>, int>((ref, surahNumber) async {
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getTajweedTexts(surahNumber);
});

final surahTranslationsProvider =
    FutureProvider.family<Map<int, String>, String>((ref, key) async {
  final parts = key.split(':');
  final surahNumber = int.parse(parts[0]);
  final resourceId = int.parse(parts[1]);
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getTranslations(surahNumber, resourceId: resourceId);
});

class MushafScreen extends ConsumerWidget {
  final bool tajweedMode;

  const MushafScreen({super.key, this.tajweedMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        title: Text(
          tajweedMode ? 'التجويد' : 'فهرس القرآن',
          style: ItqanTypography.heading2,
        ),
        backgroundColor: ItqanColors.void_,
        actions: [
          IconButton(
            tooltip: 'البحث في القرآن',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuranSearchScreen(
                  service: ref.read(quranServiceProvider),
                ),
              ),
            ),
            icon: const Icon(Icons.search_rounded, color: ItqanColors.gold),
          ),
        ],
      ),
      body: surahsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ItqanColors.gold),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: ItqanColors.mist, size: 48),
              const SizedBox(height: ItqanSpacing.md),
              Text('Could not load surahs\n$err',
                  style: ItqanTypography.body, textAlign: TextAlign.center),
              const SizedBox(height: ItqanSpacing.md),
              ElevatedButton(
                onPressed: () => ref.refresh(surahsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (surahs) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            ItqanSpacing.md,
            ItqanSpacing.sm,
            ItqanSpacing.md,
            ItqanSpacing.xl,
          ),
          itemCount: surahs.length,
          separatorBuilder: (_, __) => const SizedBox(height: ItqanSpacing.xs),
          itemBuilder: (context, index) => _SurahTile(
            surah: surahs[index],
            tajweedMode: tajweedMode,
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final bool tajweedMode;

  const _SurahTile({required this.surah, this.tajweedMode = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ItqanColors.onyx,
      borderRadius: BorderRadius.circular(ItqanRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(ItqanRadius.md),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _AyahListScreen(
              surah: surah,
              tajweedMode: tajweedMode,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ItqanSpacing.md,
            vertical: ItqanSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ItqanRadius.md),
            border:
                Border.all(color: ItqanColors.charcoal.withOpacity(0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ItqanColors.charcoal,
                  borderRadius: BorderRadius.circular(ItqanRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  surah.number.toString().padLeft(3, '0'),
                  style: const TextStyle(
                    color: ItqanColors.snow,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: ItqanSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 19,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: ItqanColors.gold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.nameTranslation}  ·  ${surah.ayahCount} ayahs',
                      style: ItqanTypography.caption.copyWith(
                        color: ItqanColors.silver,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ItqanSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: ItqanColors.mist),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahListScreen extends ConsumerStatefulWidget {
  final Surah surah;
  final bool tajweedMode;

  const _AyahListScreen({required this.surah, this.tajweedMode = false});

  @override
  ConsumerState<_AyahListScreen> createState() => _AyahListScreenState();
}

class _AyahListScreenState extends ConsumerState<_AyahListScreen> {
  bool _tajweedEnabled = false;

  @override
  void initState() {
    super.initState();
    _tajweedEnabled = widget.tajweedMode;
  }

  Future<void> _showTafsirSheet(Ayah ayah, {String? translation}) async {
    final service = ref.read(quranServiceProvider);
    await service.init();
    if (!mounted) return;
    final tafsirFuture = service.getTafsir(ayah.verseKey);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ItqanColors.slate,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: ItqanSpacing.md),
              Text(
                'تفسير ابن كثير · ${widget.surah.nameArabic} · الآية ${ayah.ayahNumber}',
                style: ItqanTypography.heading2,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: ItqanSpacing.md),
              Text(
                ayah.textUthmani,
                style: ItqanTypography.arabicLarge,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              if ((translation ?? ayah.translation).isNotEmpty) ...[
                const SizedBox(height: ItqanSpacing.sm),
                Text(translation ?? ayah.translation,
                    style: ItqanTypography.caption),
              ],
              const Divider(height: ItqanSpacing.lg),
              Expanded(
                child: FutureBuilder<String>(
                  future: tafsirFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: ItqanColors.gold),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'تعذر تحميل التفسير: ${snapshot.error}',
                          style: ItqanTypography.body
                              .copyWith(color: ItqanColors.error),
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: SelectableText(
                        snapshot.data?.isNotEmpty == true
                            ? snapshot.data!
                            : 'لا يتوفر تفسير لهذه الآية.',
                        style: ItqanTypography.body.copyWith(height: 1.8),
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final ayahsAsync = ref.watch(ayahsProvider(surah.number));
    final tajweedTextsAsync =
        _tajweedEnabled ? ref.watch(tajweedTextsProvider(surah.number)) : null;
    final settings = ref.watch(settingsProvider);
    final translationResourceId = switch (settings.translationLanguage) {
      'english' => 20,
      'french' => 31,
      _ => null,
    };
    final translationsAsync = translationResourceId == null
        ? null
        : ref.watch(surahTranslationsProvider(
            '${surah.number}:$translationResourceId',
          ));
    // Sync toggle with global setting on first build
    if (settings.tajweedOverlay != _tajweedEnabled && !_tajweedEnabled) {
      _tajweedEnabled = settings.tajweedOverlay;
    }

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        title: Text(surah.nameSimple, style: ItqanTypography.heading2),
        backgroundColor: ItqanColors.void_,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_fix_high_rounded,
                color: _tajweedEnabled ? ItqanColors.gold : ItqanColors.mist),
            tooltip: 'ألوان التجويد من مصدر موثق (تحتاج اتصالًا)',
            onPressed: () {
              final enable = !_tajweedEnabled;
              setState(() => _tajweedEnabled = enable);
              if (enable) {
                ref.read(tajweedTextsProvider(surah.number).future).then(
                  (_) {},
                  onError: (Object error, StackTrace stackTrace) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تعذر تحميل ألوان التجويد. نص القرآن متاح دون اتصال، والتلوين يحتاج اتصالًا.',
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: ItqanSpacing.md),
            child: Text(
              surah.nameArabic,
              style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 20,
                  color: ItqanColors.gold),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
      body: ayahsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: ItqanColors.gold)),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: ItqanTypography.body)),
        data: (ayahs) => ListView.builder(
          padding: const EdgeInsets.all(ItqanSpacing.md),
          itemCount: ayahs.length,
          itemBuilder: (context, index) {
            final ayah = ayahs[index];
            final translation =
                translationsAsync?.asData?.value[ayah.ayahNumber] ??
                    ayah.translation;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecitationScreen(
                    ayah: ayah,
                    surahName: surah.nameSimple,
                    tajweedMode: widget.tajweedMode,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
                padding: const EdgeInsets.all(ItqanSpacing.md),
                decoration: BoxDecoration(
                  color: ItqanColors.onyx,
                  borderRadius: BorderRadius.circular(ItqanRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ItqanColors.goldShimmer,
                            borderRadius:
                                BorderRadius.circular(ItqanRadius.full),
                          ),
                          child: Text('${ayah.ayahNumber}',
                              style: const TextStyle(
                                  color: ItqanColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          tooltip: 'تفسير ابن كثير',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showTafsirSheet(
                            ayah,
                            translation: translation,
                          ),
                          icon: const Icon(
                            Icons.menu_book_rounded,
                            color: ItqanColors.gold,
                            size: 19,
                          ),
                        ),
                        const Icon(Icons.mic_rounded,
                            color: ItqanColors.mist, size: 18),
                      ],
                    ),
                    const SizedBox(height: ItqanSpacing.sm),
                    _tajweedEnabled
                        ? _TajweedAyahText(
                            ayah: ayah,
                            taggedText: tajweedTextsAsync
                                ?.asData?.value[ayah.ayahNumber],
                          )
                        : Text(
                            ayah.textUthmani,
                            style: const TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 22,
                              height: 2.0,
                              color: ItqanColors.snow,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                    if (translation.isNotEmpty) ...[
                      const SizedBox(height: ItqanSpacing.sm),
                      Text(
                        translation,
                        style: ItqanTypography.caption,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TajweedAyahText extends StatelessWidget {
  final Ayah ayah;
  final String? taggedText;
  const _TajweedAyahText({required this.ayah, required this.taggedText});

  @override
  Widget build(BuildContext context) {
    final markupIsValid = taggedText != null &&
        tajweedMarkupMatchesText(taggedText!, ayah.textUthmani);
    final span = markupIsValid
        ? tajweedApiMarkupSpan(taggedText!)
        : TextSpan(
            text: ayah.textUthmani,
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 22,
              height: 2,
              color: ItqanColors.ink,
            ),
          );
    return Text.rich(
      span,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }
}
