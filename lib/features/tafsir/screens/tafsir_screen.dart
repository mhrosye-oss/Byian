import 'package:flutter/material.dart';

import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/features/quran/models/ayah.dart';
import 'package:itqan/features/quran/services/quran_service.dart';

class TafsirScreen extends StatefulWidget {
  const TafsirScreen({super.key});

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  static const Duration _requestTimeout = Duration(seconds: 25);

  final QuranService _quran = QuranService();
  late Future<List<Surah>> _surahs;

  final Map<String, Future<String>> _tafsirRequests = {};

  int? _selected;
  List<Ayah> _ayahs = const [];
  bool _loadingAyahs = false;
  bool _ayahLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _surahs = _loadSurahs();
  }

  Future<List<Surah>> _loadSurahs() async {
    await _quran.init().timeout(_requestTimeout);
    return _quran.getSurahs().timeout(_requestTimeout);
  }

  Future<void> _reloadSurahs() async {
    setState(() {
      _surahs = _loadSurahs();
    });
  }

  Future<void> _selectSurah(Surah surah) async {
    setState(() {
      _selected = surah.number;
      _loadingAyahs = true;
      _ayahLoadFailed = false;
      _ayahs = const [];
      _tafsirRequests.clear();
    });

    try {
      await _quran.init().timeout(_requestTimeout);
      final verses =
          await _quran.getAyahs(surah.number).timeout(_requestTimeout);

      if (!mounted || _selected != surah.number) return;
      setState(() {
        _ayahs = verses;
        _loadingAyahs = false;
      });
    } catch (_) {
      if (!mounted || _selected != surah.number) return;
      setState(() {
        _loadingAyahs = false;
        _ayahLoadFailed = true;
      });
    }
  }

  Future<String> _tafsirFor(Ayah ayah) {
    return _tafsirRequests.putIfAbsent(ayah.verseKey, () async {
      await _quran.init().timeout(_requestTimeout);
      final text = await _quran
          .getTafsir(ayah.verseKey)
          .timeout(_requestTimeout);

      if (text.trim().isEmpty) {
        throw StateError('لم يرجع مصدر التفسير نصًا لهذه الآية.');
      }
      return text;
    });
  }

  void _retryTafsir(Ayah ayah) {
    setState(() {
      _tafsirRequests.remove(ayah.verseKey);
    });
  }

  void _backToSurahs() {
    setState(() {
      _selected = null;
      _ayahs = const [];
      _loadingAyahs = false;
      _ayahLoadFailed = false;
      _tafsirRequests.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_selected == null ? 'التفاسير' : 'تفسير القرآن'),
        centerTitle: true,
        leading: _selected == null
            ? null
            : IconButton(
                tooltip: 'العودة إلى قائمة السور',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backToSurahs,
              ),
      ),
      body: _selected == null ? _surahList() : _verseList(),
    );
  }

  Widget _surahList() {
    return FutureBuilder<List<Surah>>(
      future: _surahs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ItqanColors.emerald),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعذر تحميل قائمة السور.',
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _reloadSurahs,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final rows = snapshot.data ?? const <Surah>[];
        if (rows.isEmpty) {
          return const Center(
            child: Text('لا توجد سور متاحة.', textDirection: TextDirection.rtl),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final surah = rows[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ItqanColors.emerald.withOpacity(.1),
                  child: Text(
                    '${surah.number}',
                    style: const TextStyle(
                      color: ItqanColors.emerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 21,
                  ),
                ),
                subtitle: Text('${surah.nameSimple} • ${surah.ayahCount} آية'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _selectSurah(surah),
              ),
            );
          },
        );
      },
    );
  }

  Widget _verseList() {
    if (_loadingAyahs) {
      return const Center(
        child: CircularProgressIndicator(color: ItqanColors.emerald),
      );
    }

    if (_ayahLoadFailed) {
      return Center(
        child: TextButton.icon(
          onPressed: _retrySelectedSurah,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(
            'تعذر تحميل الآيات. أعد المحاولة.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    if (_ayahs.isEmpty) {
      return const Center(
        child: Text('لا توجد آيات متاحة لهذه السورة.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ayahs.length,
      itemBuilder: (context, index) {
        final ayah = _ayahs[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${ayah.textUthmani}  ﴿${ayah.ayahNumber}﴾',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 23,
                    height: 1.9,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Divider(height: 24),
                FutureBuilder<String>(
                  future: _tafsirFor(ayah),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ItqanColors.emerald,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'جارٍ تحميل التفسير…',
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError ||
                        (snapshot.data ?? '').trim().isEmpty) {
                      return Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          const Expanded(
                            child: Text(
                              'تعذر تحميل التفسير. تحقق من اتصال الإنترنت.',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(color: ItqanColors.error),
                            ),
                          ),
                          IconButton(
                            tooltip: 'إعادة المحاولة',
                            onPressed: () => _retryTafsir(ayah),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: ItqanColors.emerald,
                            ),
                          ),
                        ],
                      );
                    }

                    return SelectableText(
                      snapshot.data!,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _retrySelectedSurah() {
    final surahNumber = _selected;
    if (surahNumber == null) return;

    _selectSurah(
      Surah(
        number: surahNumber,
        nameArabic: '',
        nameSimple: '',
        nameTranslation: '',
        ayahCount: 0,
        revelationPlace: '',
      ),
    );
  }
}
