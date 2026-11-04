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
    _surahs = _quran.getSurahs();
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
      final verses = await _quran.getAyahs(surah.number);
      if (mounted) setState(() { _ayahs = verses; _loadingAyahs = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingAyahs = false; _ayahLoadFailed = true; });
    }
  }

  Future<String> _tafsirFor(Ayah ayah) => _tafsirRequests.putIfAbsent(
        ayah.verseKey,
        () async {
          final text = await _quran.getTafsir(ayah.verseKey);
          if (text.trim().isEmpty) throw StateError('لم يرجع مصدر التفسير نصًا لهذه الآية.');
          return text;
        },
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          title: Text(_selected == null ? 'التفاسير' : 'تفسير القرآن'),
          leading: _selected == null ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() { _selected = null; _ayahs = const []; }),
          ),
        ),
        body: _selected == null ? _surahList() : _verseList(),
      );

  Widget _surahList() => FutureBuilder<List<Surah>>(
        future: _surahs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل قائمة السور.'));
          final rows = snapshot.data ?? const <Surah>[];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final surah = rows[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: ItqanColors.emerald.withOpacity(.1), child: Text('${surah.number}', style: const TextStyle(color: ItqanColors.emerald))),
                  title: Text(surah.nameArabic, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 21)),
                  subtitle: Text('${surah.nameSimple} • ${surah.ayahCount} آية'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectSurah(surah),
                ),
              );
            },
          );
        },
      );

  Widget _verseList() {
    if (_loadingAyahs) return const Center(child: CircularProgressIndicator());
    if (_ayahLoadFailed) {
      return Center(child: TextButton.icon(
        onPressed: () {
          final surahNumber = _selected;
          if (surahNumber == null) return;
          _selectSurah(Surah(number: surahNumber, nameArabic: '', nameSimple: '', nameTranslation: '', ayahCount: 0, revelationPlace: ''));
        },
        icon: const Icon(Icons.refresh),
        label: const Text('تعذر تحميل الآيات. أعد المحاولة.'),
      ));
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${ayah.textUthmani}  ﴿${ayah.ayahNumber}﴾', textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 23, height: 1.9, color: ItqanColors.ink)),
              const Divider(height: 24),
              FutureBuilder<String>(
                future: _tafsirFor(ayah),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(textDirection: TextDirection.rtl, children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('جارٍ تحميل التفسير…', textDirection: TextDirection.rtl),
                      ]),
                    );
                  }
                  if (snapshot.hasError || (snapshot.data ?? '').trim().isEmpty) {
                    return Row(textDirection: TextDirection.rtl, children: [
                      const Expanded(child: Text('تعذر تحميل التفسير. تحقق من اتصال الإنترنت.', textDirection: TextDirection.rtl, style: TextStyle(color: ItqanColors.inkSoft))),
                      IconButton(
                        tooltip: 'إعادة المحاولة',
                        onPressed: () => setState(() => _tafsirRequests.remove(ayah.verseKey)),
                        icon: const Icon(Icons.refresh_rounded, color: ItqanColors.emerald),
                      ),
                    ]);
                  }
                  return Text(snapshot.data!, textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 15, height: 1.8, color: ItqanColors.inkSoft));
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}
