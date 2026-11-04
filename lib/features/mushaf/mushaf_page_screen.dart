import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../recitation/recitation_screen.dart';
import '../settings/settings_service.dart';
import '../tajweed/tajweed_data.dart';
import 'mushaf_screen.dart';
import 'providers/reading_position_provider.dart';
import 'services/reading_position_service.dart';

final _pageDataProvider = FutureProvider.family<PageData, int>((ref, page) async {
  if (page < 1 || page > 604) {
    return PageData(pageNumber: page, juzNumber: 0, hizbNumber: 0, verses: []);
  }
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getPage(page);
});

final _pageTranslationsProvider =
    FutureProvider.family<Map<String, String>, String>((ref, key) async {
  final parts = key.split(':');
  final pageNumber = int.parse(parts[0]);
  final resourceId = int.parse(parts[1]);
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getPageTranslations(pageNumber, resourceId: resourceId);
});

final _surahTajweedProvider =
    FutureProvider.family<Map<int, String>, int>((ref, surahNumber) async {
  final service = ref.read(quranServiceProvider);
  await service.init();
  return service.getTajweedTexts(surahNumber);
});

/// The page-based Mushaf reader. Surah Browser continues to open this screen
/// using its selected surah's starting page; the Surah Index is not changed.
class MushafPageScreen extends ConsumerStatefulWidget {
  final int startPage;

  const MushafPageScreen({super.key, this.startPage = 1});

  @override
  ConsumerState<MushafPageScreen> createState() => _MushafPageScreenState();
}

class _MushafPageScreenState extends ConsumerState<MushafPageScreen> {
  late int _currentPage;
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  OverlayEntry? _ayahMenuEntry;
  VerseOnPage? _menuVerse;
  bool _showTranslation = true;
  bool _autoScroll = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.startPage.clamp(1, 604);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveReadingPosition(_currentPage);
    });
  }

  @override
  void dispose() {
    _dismissAyahMenu();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > 604 || page == _currentPage) return;
    setState(() {
      _currentPage = page;
      _autoScroll = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _saveReadingPosition(page);
  }

  Future<void> _saveReadingPosition(int page) async {
    try {
      final pageData = await ref.read(_pageDataProvider(page).future);
      if (pageData.verses.isEmpty) return;
      final verse = pageData.verses.first;
      final surahs = await ref.read(surahsProvider.future);
      final surah = surahs.where((item) => item.number == verse.surahNumber).firstOrNull;
      await ref.read(readingPositionServiceProvider).saveLastPosition(
            ReadingPosition(
              pageNumber: page,
              surahNumber: verse.surahNumber,
              ayahNumber: verse.ayahNumber,
              surahNameSimple: surah?.nameSimple ?? '',
              surahNameArabic: surah?.nameArabic ?? '',
              savedAt: DateTime.now(),
            ),
          );
      ref.invalidate(lastReadingPositionProvider);
    } catch (_) {
      // A failure to persist the reading position must not interrupt reading.
    }
  }

  Future<void> _toggleBookmark(VerseOnPage verse, {String? label}) async {
    try {
      final surahs = await ref.read(surahsProvider.future);
      final surah = surahs.where((item) => item.number == verse.surahNumber).firstOrNull;
      await ref.read(bookmarksProvider.notifier).add(
            ReadingPosition(
              pageNumber: _currentPage,
              surahNumber: verse.surahNumber,
              ayahNumber: verse.ayahNumber,
              surahNameSimple: surah?.nameSimple ?? '',
              surahNameArabic: surah?.nameArabic ?? '',
              savedAt: DateTime.now(),
            ),
            label: label,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الآية في الإشارات المرجعية')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الإشارة المرجعية')),
        );
      }
    }
  }

  Future<void> _bookmarkWithNote(VerseOnPage verse) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('إضافة ملاحظة', textDirection: TextDirection.rtl),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظة لهذه الآية'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    controller.dispose();
    if (label != null) await _toggleBookmark(verse, label: label.isEmpty ? null : label);
  }

  Future<void> _playVerse(VerseOnPage verse) async {
    try {
      final ayah = Ayah(
        surahNumber: verse.surahNumber,
        ayahNumber: verse.ayahNumber,
        textUthmani: verse.textUthmani,
        words: const [],
        translation: verse.translation,
      );
      await _audioPlayer.setUrl(ayah.audioUrl);
      await _audioPlayer.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل الآية. تحقق من اتصال الإنترنت.')),
        );
      }
    }
  }

  Future<void> _shareVerse(VerseOnPage verse) async {
    final text = '${verse.textUthmani}\n(${verse.surahNumber}:${verse.ayahNumber})';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الآية لمشاركتها')),
      );
    }
  }

  void _showAyahMenu(VerseOnPage verse, Offset globalPosition) {
    _dismissAyahMenu();
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final local = overlayBox.globalToLocal(globalPosition);
    const menuWidth = 292.0;
    const menuHeight = 68.0;
    final left = (local.dx - menuWidth / 2).clamp(8.0, overlayBox.size.width - menuWidth - 8.0);
    final top = (local.dy - menuHeight - 12).clamp(8.0, overlayBox.size.height - menuHeight - 8.0);
    _menuVerse = verse;

    _ayahMenuEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissAyahMenu,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            height: menuHeight,
            child: Material(
              color: Colors.white,
              elevation: 12,
              borderRadius: BorderRadius.circular(36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FloatingMenuButton(icon: Icons.play_arrow_rounded, color: const Color(0xFF1B5E20), tooltip: 'تشغيل', onTap: () { _dismissAyahMenu(); _playVerse(verse); }),
                  _FloatingMenuButton(icon: Icons.star_rounded, color: const Color(0xFFE0A800), tooltip: 'إشارة مرجعية', onTap: () { _dismissAyahMenu(); _toggleBookmark(verse); }),
                  _FloatingMenuButton(icon: Icons.edit_note_rounded, color: const Color(0xFFE0A800), tooltip: 'إشارة مع ملاحظة', onTap: () { _dismissAyahMenu(); _bookmarkWithNote(verse); }),
                  _FloatingMenuButton(icon: Icons.share_rounded, color: const Color(0xFF1B5E20), tooltip: 'مشاركة', onTap: () { _dismissAyahMenu(); _shareVerse(verse); }),
                  _FloatingMenuButton(icon: Icons.close_rounded, color: const Color(0xFF687268), tooltip: 'إغلاق', onTap: _dismissAyahMenu),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_ayahMenuEntry!);
  }

  void _dismissAyahMenu() {
    _ayahMenuEntry?.remove();
    _ayahMenuEntry = null;
    _menuVerse = null;
  }

  void _toggleAutoScroll() {
    setState(() => _autoScroll = !_autoScroll);
    if (_autoScroll && _scrollController.hasClients) {
      final distance = _scrollController.position.maxScrollExtent - _scrollController.offset;
      if (distance > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(seconds: (distance / 12).ceil().clamp(20, 180)),
          curve: Curves.linear,
        ).whenComplete(() {
          if (mounted) setState(() => _autoScroll = false);
        });
      }
    } else if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
  }

  Future<void> _showTafsir(VerseOnPage verse) async {
    final service = ref.read(quranServiceProvider);
    final future = service.getTafsir(verse.verseKey);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('تفسير الآية ${verse.ayahNumber}', textDirection: TextDirection.rtl, style: ItqanTypography.heading2),
              const SizedBox(height: 12),
              Text(verse.textUthmani, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 22, height: 1.8)),
              const Divider(height: 28),
              Expanded(child: FutureBuilder<String>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                  if (snapshot.hasError || (snapshot.data ?? '').isEmpty) return const Center(child: Text('تعذر تحميل التفسير.', textDirection: TextDirection.rtl));
                  return SingleChildScrollView(child: Text(snapshot.data!, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16, height: 1.8)));
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showPagePicker() async {
    final controller = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الانتقال إلى صفحة', textDirection: TextDirection.rtl),
        content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)), child: const Text('انتقال')),
        ],
      ),
    );
    controller.dispose();
    if (page != null) _goToPage(page.clamp(1, 604));
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(_pageDataProvider(_currentPage));
    final settings = ref.watch(settingsProvider);
    final translationResourceId = switch (settings.translationLanguage) {
      'english' => 20,
      'french' => 31,
      _ => 20,
    };
    final translationsAsync = _showTranslation
        ? ref.watch(_pageTranslationsProvider('$_currentPage:$translationResourceId'))
        : null;
    final translation = translationsAsync?.asData?.value ?? const <String, String>{};
    final firstVerse = pageAsync.asData?.value.verses.firstOrNull;
    final surahName = firstVerse == null
        ? 'المصحف الشريف'
        : ref.watch(surahsProvider).maybeWhen(
              data: (surahs) => surahs.where((s) => s.number == firstVerse.surahNumber).firstOrNull?.nameArabic ?? 'سورة القرآن',
              orElse: () => 'سورة القرآن',
            );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(
        child: Column(
          children: [
            _ReaderHeader(
              surahName: surahName,
              page: _currentPage,
              translationEnabled: _showTranslation,
              onPrevious: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
              onNext: _currentPage < 604 ? () => _goToPage(_currentPage + 1) : null,
              onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
            ),
            if (_showTranslation && translationsAsync?.isLoading == true)
              const LinearProgressIndicator(minHeight: 2, color: Color(0xFF1B5E20), backgroundColor: Colors.transparent),
            Expanded(
              child: pageAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
                error: (error, _) => Center(child: Text('تعذر تحميل الصفحة. تحقق من اتصال الإنترنت.\n$error', textAlign: TextAlign.center, textDirection: TextDirection.rtl)),
                data: (pageData) => pageData.verses.isEmpty
                    ? const Center(child: Text('لا توجد آيات في هذه الصفحة'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                        itemCount: pageData.verses.length,
                        itemBuilder: (context, index) {
                          final verse = pageData.verses[index];
                          final surah = ref.watch(surahsProvider).maybeWhen(
                                data: (surahs) => surahs.where((s) => s.number == verse.surahNumber).firstOrNull,
                                orElse: () => null,
                              );
                          return _AyahCard(
                            key: ValueKey(verse.verseKey),
                            verse: verse,
                            surahName: surah?.nameArabic ?? '',
                            translation: translation[verse.verseKey] ?? verse.translation,
                            showTranslation: _showTranslation,
                            onLongPress: (position) => _showAyahMenu(verse, position),
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => RecitationScreen(
                                  ayah: Ayah(surahNumber: verse.surahNumber, ayahNumber: verse.ayahNumber, textUthmani: verse.textUthmani, words: const [], translation: verse.translation),
                                  surahName: surah?.nameSimple ?? 'القرآن الكريم',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            _ReaderBottomBar(
              autoScroll: _autoScroll,
              onListen: () { if (firstVerse != null) _playVerse(firstVerse); },
              onTafsir: () { if (firstVerse != null) _showTafsir(firstVerse); },
              onAutoScroll: _toggleAutoScroll,
              onShare: () { if (firstVerse != null) _shareVerse(firstVerse); },
              onTranslation: () => setState(() => _showTranslation = !_showTranslation),
              onBookmark: () { if (firstVerse != null) _toggleBookmark(firstVerse); },
              onMore: _showPagePicker,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.surahName, required this.page, required this.translationEnabled, required this.onPrevious, required this.onNext, required this.onToggleTranslation});

  final String surahName;
  final int page;
  final bool translationEnabled;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToggleTranslation;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 3))]),
        child: Row(
          children: [
            IconButton(onPressed: onPrevious, tooltip: 'الصفحة السابقة', color: const Color(0xFF1B5E20), icon: const Icon(Icons.chevron_left_rounded)),
            IconButton(onPressed: onNext, tooltip: 'الصفحة التالية', color: const Color(0xFF1B5E20), icon: const Icon(Icons.chevron_right_rounded)),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(surahName, textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: Color(0xFF1B5E20), fontSize: 19, fontWeight: FontWeight.w700)),
                Text('صفحة $page', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF687268), fontSize: 12)),
              ]),
            ),
            IconButton(
              onPressed: onToggleTranslation,
              tooltip: translationEnabled ? 'إخفاء الترجمة' : 'إظهار الترجمة الإنجليزية',
              color: const Color(0xFF1B5E20),
              icon: Icon(Icons.translate_rounded, color: translationEnabled ? const Color(0xFF1B5E20) : const Color(0xFF9AA39A)),
            ),
          ],
        ),
      );
}

class _AyahCard extends ConsumerWidget {
  const _AyahCard({super.key, required this.verse, required this.surahName, required this.translation, required this.showTranslation, required this.onLongPress, required this.onTap});

  final VerseOnPage verse;
  final String surahName;
  final String translation;
  final bool showTranslation;
  final ValueChanged<Offset> onLongPress;
  final VoidCallback onTap;

  String _arabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => digits[int.parse(digit)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tajweedAsync = ref.watch(_surahTajweedProvider(verse.surahNumber));
    final taggedText = tajweedAsync.asData?.value[verse.ayahNumber];
    final validMarkup = taggedText != null && tajweedMarkupMatchesText(taggedText, verse.textUthmani);
    final arabic = validMarkup
        ? tajweedApiMarkupSpan(taggedText, fontSize: 24)
        : TextSpan(text: verse.textUthmani, style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 24, height: 2.0, color: Color(0xFF263329)));
    return Column(
      children: [
        if (verse.isFirstOfSurah)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10, top: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E0D5))),
            child: Text(surahName.isEmpty ? 'سورة ${verse.surahNumber}' : surahName, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        GestureDetector(
          onTap: onTap,
          onLongPressStart: (details) => onLongPress(details.globalPosition),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0C263329), blurRadius: 10, offset: Offset(0, 3))]),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTranslation)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 3),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(translation.isEmpty ? 'Translation unavailable.' : translation, textAlign: TextAlign.left, style: const TextStyle(fontSize: 14, height: 1.65, color: Color(0xFF687268))),
                      ),
                    ),
                  ),
                if (showTranslation) Container(width: 1, height: 56, margin: const EdgeInsets.symmetric(horizontal: 4), color: const Color(0xFFE7E0D5)),
                Expanded(
                  flex: 6,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: RichText(
                      textAlign: TextAlign.right,
                      text: TextSpan(children: [
                        arabic,
                        TextSpan(text: '  ۞${_arabicNumber(verse.ayahNumber)}', style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 17, color: Color(0xFF1B5E20))),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({required this.autoScroll, required this.onListen, required this.onTafsir, required this.onAutoScroll, required this.onShare, required this.onTranslation, required this.onBookmark, required this.onMore});

  final bool autoScroll;
  final VoidCallback onListen;
  final VoidCallback onTafsir;
  final VoidCallback onAutoScroll;
  final VoidCallback onShare;
  final VoidCallback onTranslation;
  final VoidCallback onBookmark;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -3))]),
        child: SafeArea(
          top: false,
          child: Row(children: [
            _BottomAction(icon: Icons.headphones_rounded, label: 'سماع', onTap: onListen),
            _BottomAction(icon: Icons.menu_book_rounded, label: 'المراجع', onTap: onTafsir),
            _BottomAction(icon: autoScroll ? Icons.pause_circle_outline_rounded : Icons.slow_motion_video_rounded, label: 'لف تلقائي', onTap: onAutoScroll, selected: autoScroll),
            _BottomAction(icon: Icons.share_rounded, label: 'مشاركة', onTap: onShare),
            _BottomAction(icon: Icons.translate_rounded, label: 'الترجمة', onTap: onTranslation),
            _BottomAction(icon: Icons.bookmark_add_outlined, label: 'الحفظ', onTap: onBookmark),
            _BottomAction(icon: Icons.more_horiz_rounded, label: 'مزيد', onTap: onMore),
          ]),
        ),
      );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.icon, required this.label, required this.onTap, this.selected = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 21, color: selected ? const Color(0xFFE0A800) : const Color(0xFF1B5E20)),
              const SizedBox(height: 3),
              FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 9, color: Color(0xFF526052)))),
            ]),
          ),
        ),
      );
}

class _FloatingMenuButton extends StatelessWidget {
  const _FloatingMenuButton({required this.icon, required this.color, required this.tooltip, required this.onTap});

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onTap,
          style: IconButton.styleFrom(backgroundColor: color.withOpacity(.10), foregroundColor: color, fixedSize: const Size(44, 44)),
          icon: Icon(icon, size: 23),
        ),
      );
}
