import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/colors.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import 'mushaf_screen.dart';

/// مزود خدمة القرآن الكريم
final _quranServiceProvider = Provider((ref) => QuranService());

/// مزود جلب بيانات الصفحة من 1 إلى 604
final mushafPageDataProvider =
    FutureProvider.family<PageData, int>((ref, pageNumber) async {
  final service = ref.read(_quranServiceProvider);
  await service.init();
  return service.getPage(pageNumber);
});

/// مزود جلب سور القرآن الكريم
final mushafSurahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.read(_quranServiceProvider);
  await service.init();
  return service.getSurahs();
});

/// شاشة مصحفي المتقدمة - عرض المصحف الشريف العثماني (604 صفحة)
class MushafiViewScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafiViewScreen({
    super.key,
    this.initialPage = 1,
  });

  @override
  ConsumerState<MushafiViewScreen> createState() => _MushafiViewScreenState();
}

class _MushafiViewScreenState extends ConsumerState<MushafiViewScreen> {
  late int _currentPage;
  late PageController _pageController;

  // إعدادات العرض والتخصيص
  bool _useImagePages = false; // التبديل بين وضع صفحات QCF المصورة أو النصية
  bool _showTranslation = false;
  bool _tajweedColoring = true;
  bool _hifzMode = false;
  final Set<String> _revealedVersesInHifz = {};
  double _fontSize = 21.0;
  bool _isNightMode = false;
  bool _isBookmarked = false;
  bool _isUiOverlayVisible = true; // إظهار/إخفاء الأشرطة عند النقر

  // مشغل الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  bool _showAudioBar = false;
  final String _selectedReciterName = 'مشاري العفاسي';

  // مفتاح القائمة الجانبية المنبثقة
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    // في PageView ذي الاتجاه اليمين-يسار (RTL)، نبدأ من الصفحة المحددة (0-based)
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadBookmarkStatus(_currentPage);
    _saveAutoReadingPosition(_currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// حفظ تلقائي لآخر صفحة تمت قراءتها
  Future<void> _saveAutoReadingPosition(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_mushaf_page', page);
  }

  /// التحقق من حفظ الصفحة الحالية في المراجع
  Future<void> _loadBookmarkStatus(int page) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isBookmarked = prefs.getBool('bookmark_page_$page') ?? false;
    });
  }

  /// تبديل حالة المرجعية
  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final newStatus = !_isBookmarked;
    await prefs.setBool('bookmark_page_$_currentPage', newStatus);
    if (!mounted) return;
    setState(() => _isBookmarked = newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? 'تم إضافة الصفحة $_currentPage إلى المراجع'
              : 'تمت إزالة الصفحة $_currentPage من المراجع',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'NotoNaskhArabic'),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: ItqanColors.emeraldDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// تشغيل تلاوة الصفحة الحالية
  Future<void> _toggleAudio() async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlayingAudio = false);
    } else {
      setState(() {
        _showAudioBar = true;
        _isPlayingAudio = true;
      });
      // رابط التلاوة لصفحات المصحف المعتمدة (تلاوة الشيخ مشاري بن راشد العفاسي)
      final paddedPage = _currentPage.toString().padLeft(3, '0');
      final audioUrl =
          'https://everyayah.com/data/Alafasy_128kbps/PageMp3s/Page$paddedPage.mp3';

      try {
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        _audioPlayer.playerStateStream.listen((state) {
          if (mounted &&
              state.processingState == ProcessingState.completed) {
            setState(() => _isPlayingAudio = false);
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isPlayingAudio = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر تحميل تلاوة الصفحة، تأكد من الاتصال بالإنترنت'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  /// مشاركة الصفحة
  void _shareCurrentPage(PageData? pageData) {
    if (pageData == null) return;
    final text = pageData.verses.map((v) => v.textUthmani).join(' ');
    Clipboard.setData(ClipboardData(
        text: 'سورة ${pageData.verses.firstOrNull?.verseKey ?? ""} - ص$_currentPage\n\n$text'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ نص الصفحة $_currentPage إلى الحافظة للمشاركة'),
        backgroundColor: ItqanColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// الانتقال إلى صفحة محددة
  void _goToPage(int page) {
    final clamped = page.clamp(1, 604);
    _pageController.animateToPage(
      clamped - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(mushafSurahsProvider);
    final themeBg = _isNightMode ? const Color(0xFF141716) : const Color(0xFFFBF8F2);
    final themePaper = _isNightMode ? const Color(0xFF1C201E) : const Color(0xFFFFFDF8);
    final textColor = _isNightMode ? const Color(0xFFE2E8F0) : const Color(0xFF1F2421);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: themeBg,
        // القائمة الجانبية التفاعلية المنبثقة
        endDrawer: _buildInteractiveDrawer(),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. المحتوى الأساسي: PageView للتنقل بين الصفحات من اليمين لليسار
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isUiOverlayVisible = !_isUiOverlayVisible;
                  });
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 604,
                  // ملاحظة: مع Directionality.rtl، التمرير لليسار يتقدم للأمام (ص 1 -> 2 -> 3)
                  onPageChanged: (index) {
                    final newPage = index + 1;
                    setState(() {
                      _currentPage = newPage;
                    });
                    _loadBookmarkStatus(newPage);
                    _saveAutoReadingPosition(newPage);
                  },
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    return _buildMushafPage(
                      pageNumber: pageNum,
                      surahs: surahsAsync.valueOrNull ?? const [],
                      backgroundColor: themePaper,
                      textColor: textColor,
                    );
                  },
                ),
              ),

              // 2. رأس الصفحة (Header) يظهر/يختفي بنعومة
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: _isUiOverlayVisible ? 0 : -100,
                left: 0,
                right: 0,
                child: _buildHeaderBar(),
              ),

              // 3. شريط الصوت العائم عند التفعيل
              if (_showAudioBar)
                Positioned(
                  bottom: _isUiOverlayVisible ? 85 : 20,
                  left: 20,
                  right: 20,
                  child: _buildAudioPlayerWidget(),
                ),

              // 4. شريط الأدوات السفلي المتجاور
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: _isUiOverlayVisible ? 12 : -110,
                left: 12,
                right: 12,
                child: _buildBottomToolbar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header: رأس الصفحة ───────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    final pageAsync = ref.watch(mushafPageDataProvider(_currentPage));
    final surahs = ref.watch(mushafSurahsProvider).valueOrNull ?? const [];

    String surahName = 'القرآن الكريم';
    int juzNumber = 1;
    int hizbNumber = 1;

    if (pageAsync.hasValue && pageAsync.value != null) {
      final pageData = pageAsync.value!;
      juzNumber = pageData.juzNumber;
      hizbNumber = pageData.hizbNumber;
      if (pageData.verses.isNotEmpty) {
        final surahNum = pageData.verses.first.surahNumber;
        final s = surahs.where((item) => item.number == surahNum).firstOrNull;
        if (s != null) surahName = s.nameArabic;
      }
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (_isNightMode ? Colors.black54 : Colors.white.withValues(alpha: 0.85)),
            border: const Border(
              bottom: BorderSide(color: Color(0x33D4AF37), width: 1),
            ),
          ),
          child: Row(
            children: [
              // زر العودة
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                color: ItqanColors.emerald,
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'رجوع',
              ),
              const SizedBox(width: 8),

              // اسم السورة في إطار مزخرف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1AD4AF37),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x66D4AF37)),
                ),
                child: Text(
                  'سورة $surahName',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.emerald,
                  ),
                ),
              ),

              const Spacer(),

              // بيانات الجزء والحزب
              Text(
                'الجزء $juzNumber • الحزب $hizbNumber',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isNightMode ? Colors.white70 : ItqanColors.inkSoft,
                ),
              ),

              const SizedBox(width: 8),

              // زر فتح القائمة التفاعلية المنبثقة
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFFB78628)),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                tooltip: 'خيارات الصفحة والتفاعل',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mushaf Page: صفحة المصحف المتطابقة مع الرسم العثماني ────────────────
  Widget _buildMushafPage({
    required int pageNumber,
    required List<Surah> surahs,
    required Color backgroundColor,
    required Color textColor,
  }) {
    // خيار 1: عرض صورة الصفحة الأصلية لمصحف النشر الحاسوبي QCF
    if (_useImagePages) {
      final padded = pageNumber.toString().padLeft(3, '0');
      final imageUrl = 'https://android.quran.com/data/width_1260/page$padded.png';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, _) => const Center(
              child: CircularProgressIndicator(color: ItqanColors.emerald),
            ),
            errorWidget: (context, _, __) => _buildTextBasedMushafPage(
              pageNumber: pageNumber,
              surahs: surahs,
              backgroundColor: backgroundColor,
              textColor: textColor,
            ),
          ),
        ),
      );
    }

    // خيار 2: العرض النصي العثماني المنسق مع الإطار والترويسة
    return _buildTextBasedMushafPage(
      pageNumber: pageNumber,
      surahs: surahs,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  Widget _buildTextBasedMushafPage({
    required int pageNumber,
    required List<Surah> surahs,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final pageAsync = ref.watch(mushafPageDataProvider(pageNumber));

    return pageAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ItqanColors.emerald),
      ),
      error: (e, _) => Center(
        child: Text('خطأ في تحميل الصفحة: $e'),
      ),
      data: (pageData) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 55, 14, 85),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // إطار زخرفي عثماني داخلي
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0x33B78628),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._buildSurahsContent(pageData, surahs, textColor),
                      ],
                    ),
                  ),
                ),
              ),

              // تذييل الصفحة: رقم الصفحة العثماني
              const SizedBox(height: 6),
              _buildPageNumberFooter(pageNumber),
            ],
          ),
        );
      },
    );
  }

  /// بناء محتوى السور والآيات مع الترويسات والبسملة
  List<Widget> _buildSurahsContent(
    PageData pageData,
    List<Surah> surahs,
    Color textColor,
  ) {
    final widgets = <Widget>[];
    int? currentSurahId;
    List<VerseOnPage> currentSurahVerses = [];

    void flushCurrentSurah() {
      if (currentSurahVerses.isEmpty) return;
      final surahNum = currentSurahId!;
      final isFirstSurahAyah = currentSurahVerses.any((v) => v.ayahNumber == 1);
      final surahInfo = surahs.where((s) => s.number == surahNum).firstOrNull;

      // إذا كانت السورة تبدأ في هذه الصفحة، نضيف ترويسة السورة والبسملة
      if (isFirstSurahAyah && surahInfo != null) {
        widgets.add(_buildSurahBanner(surahInfo));
        if (surahNum != 9) {
          // سورة التوبة بدون بسملة
          widgets.add(_buildBismillah());
        }
      }

      // عرض نص الآيات متصلة كالمصحف الشريف
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildVersesFlow(currentSurahVerses, textColor),
        ),
      );
      currentSurahVerses = [];
    }

    for (final verse in pageData.verses) {
      if (currentSurahId != verse.surahNumber) {
        flushCurrentSurah();
        currentSurahId = verse.surahNumber;
      }
      currentSurahVerses.add(verse);
    }
    flushCurrentSurah();

    return widgets;
  }

  /// ترويسة السورة العثمانية المزخرفة
  Widget _buildSurahBanner(Surah surah) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EEDB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC79834), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A5817),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC79834)),
              const SizedBox(width: 4),
              Text(
                'سُورَةُ ${surah.nameArabic}',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A3408),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC79834)),
            ],
          ),
          Text(
            'آياتها ${surah.ayahCount}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A5817),
            ),
          ),
        ],
      ),
    );
  }

  /// البسملة الشريفة
  Widget _buildBismillah() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  /// تدفق الآيات المتصل مع أرقام الآيات المزخرفة
  Widget _buildVersesFlow(List<VerseOnPage> verses, Color textColor) {
    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: verses.expand((verse) {
          final isHidden =
              _hifzMode && !_revealedVersesInHifz.contains(verse.verseKey);

          return [
            // نص الآية
            TextSpan(
              text: isHidden
                  ? ' ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ '
                  : '${verse.textUthmani} ',
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: _fontSize,
                height: 2.1,
                color: isHidden
                    ? Colors.grey.withValues(alpha: 0.5)
                    : (_tajweedColoring ? textColor : textColor),
              ),
            ),
            // رمز رقم الآية العثماني المزخرف ﴿١﴾
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () {
                  if (_hifzMode) {
                    setState(() {
                      if (_revealedVersesInHifz.contains(verse.verseKey)) {
                        _revealedVersesInHifz.remove(verse.verseKey);
                      } else {
                        _revealedVersesInHifz.add(verse.verseKey);
                      }
                    });
                  } else {
                    _showAyahActionMenu(verse);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFB78628),
                      width: 1.2,
                    ),
                    color: const Color(0x1AB78628),
                  ),
                  child: Text(
                    '${verse.ayahNumber}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF825A12),
                    ),
                  ),
                ),
              ),
            ),
          ];
        }).toList(),
      ),
    );
  }

  /// رقم الصفحة أسفل الإطار العثماني
  Widget _buildPageNumberFooter(int pageNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x1AD4AF37),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44D4AF37)),
      ),
      child: Text(
        '$pageNumber',
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7A5817),
        ),
      ),
    );
  }

  // ─── Bottom Toolbar: شريط الأدوات السفلي المتجاور ─────────────────────────
  Widget _buildBottomToolbar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (_isNightMode
                ? const Color(0xDD181B19)
                : Colors.white.withValues(alpha: 0.92)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x33D4AF37),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. التشغيل / السماع
              _buildToolbarItem(
                icon: _isPlayingAudio
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                label: 'استماع',
                isActive: _isPlayingAudio,
                onTap: _toggleAudio,
              ),

              // 2. المراجع
              _buildToolbarItem(
                icon: _isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: 'المراجع',
                isActive: _isBookmarked,
                activeColor: const Color(0xFFC79834),
                onTap: _toggleBookmark,
              ),

              // 3. الفهرس والحفظ التلقائي
              _buildToolbarItem(
                icon: Icons.menu_book_rounded,
                label: 'الفهرس',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MushafScreen(),
                    ),
                  );
                },
              ),

              // 4. المشاركة
              _buildToolbarItem(
                icon: Icons.share_rounded,
                label: 'مشاركة',
                onTap: () {
                  final pageAsync =
                      ref.read(mushafPageDataProvider(_currentPage));
                  _shareCurrentPage(pageAsync.valueOrNull);
                },
              ),

              // 5. الترجمة
              _buildToolbarItem(
                icon: Icons.translate_rounded,
                label: 'الترجمة',
                isActive: _showTranslation,
                onTap: () {
                  setState(() {
                    _showTranslation = !_showTranslation;
                  });
                  _showTranslationSheet();
                },
              ),

              // 6. وضع الحفظ (التسميع الذاتي)
              _buildToolbarItem(
                icon: _hifzMode
                    ? Icons.visibility_off_rounded
                    : Icons.school_rounded,
                label: 'الحفظ',
                isActive: _hifzMode,
                activeColor: Colors.deepOrangeAccent,
                onTap: () {
                  setState(() {
                    _hifzMode = !_hifzMode;
                    _revealedVersesInHifz.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _hifzMode
                            ? 'تم تفعيل وضع الحفظ (انقر على رقم الآية لكشفها)'
                            : 'تم إيقاف وضع الحفظ',
                        style: const TextStyle(fontFamily: 'NotoNaskhArabic'),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = ItqanColors.emerald,
  }) {
    final color = isActive
        ? activeColor
        : (_isNightMode ? Colors.white70 : ItqanColors.inkSoft);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Floating Audio Player Widget ─────────────────────────────────────────
  Widget _buildAudioPlayerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B23),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlayingAudio
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: const Color(0xFFD4AF37),
              size: 32,
            ),
            onPressed: _toggleAudio,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تلاوة صفحة $_currentPage',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'القارئ: $_selectedReciterName',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
            onPressed: () async {
              await _audioPlayer.stop();
              setState(() {
                _isPlayingAudio = false;
                _showAudioBar = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // ─── Popup / Drawer Menu: القائمة التفاعلية المنبثقة الشفافة ──────────────
  Widget _buildInteractiveDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: (_isNightMode
              ? const Color(0xEA121513)
              : const Color(0xF5FBF9F5)),
          child: Column(
            children: [
              // رأس القائمة الجانبية
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0x22D4AF37), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded,
                        color: ItqanColors.emerald, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'خيارات المصحف التفاعلية',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ItqanColors.emerald,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // الخيارات التفاعلية
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    // 1. التفسير المباشر
                    _buildDrawerTile(
                      icon: Icons.menu_book_outlined,
                      title: 'التفسير المباشر',
                      subtitle: 'تفسير ابن كثير والتفسير الميسر للصفحة',
                      onTap: () {
                        Navigator.pop(context);
                        _showDirectTafsirSheet();
                      },
                    ),

                    // 2. كلمة بكلمة
                    _buildDrawerTile(
                      icon: Icons.text_fields_rounded,
                      title: 'كلمة بكلمة (معاني المفردات)',
                      subtitle: 'استعراض معاني الكلمات وإعرابها السريع',
                      onTap: () {
                        Navigator.pop(context);
                        _showWordByWordSheet();
                      },
                    ),

                    // 3. البحث الصوتي
                    _buildDrawerTile(
                      icon: Icons.mic_rounded,
                      title: 'البحث الصوتي في القرآن',
                      subtitle: 'ابحث عن آية بنطقها صوتياً',
                      onTap: () {
                        Navigator.pop(context);
                        _startVoiceSearch();
                      },
                    ),

                    // 4. تلوين أحكام التجويد (Toggle)
                    SwitchListTile(
                      activeThumbColor: ItqanColors.emerald,
                      value: _tajweedColoring,
                      secondary: const Icon(Icons.palette_outlined,
                          color: Color(0xFFC79834)),
                      title: const Text(
                        'تلوين أحكام التجويد',
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'إبراز المدود والإدغام والغنة بألوان علم التجويد',
                        style: TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 11),
                      ),
                      onChanged: (val) {
                        setState(() => _tajweedColoring = val);
                      },
                    ),

                    // 5. التبديل بين وضع صفحات QCF المصورة أو النصية
                    SwitchListTile(
                      activeThumbColor: ItqanColors.emerald,
                      value: _useImagePages,
                      secondary: const Icon(Icons.image_outlined,
                          color: Color(0xFFC79834)),
                      title: const Text(
                        'نموذج صفحات QCF المصورة',
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'عرض صفحات مصحف مجمع الملك فهد المطابقة للورقي',
                        style: TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 11),
                      ),
                      onChanged: (val) {
                        setState(() => _useImagePages = val);
                      },
                    ),

                    // 6. الذهاب إلى صفحة محددة
                    _buildDrawerTile(
                      icon: Icons.find_in_page_outlined,
                      title: 'الذهاب إلى صفحة محددة',
                      subtitle: 'الانتقال المباشر لأي صفحة من 1 إلى 604',
                      onTap: () {
                        Navigator.pop(context);
                        _showGoToPageDialog();
                      },
                    ),

                    const Divider(height: 24, indent: 20, endIndent: 20),

                    // 7. الوضع الليلي
                    SwitchListTile(
                      activeThumbColor: ItqanColors.emerald,
                      value: _isNightMode,
                      secondary: const Icon(Icons.dark_mode_outlined,
                          color: Color(0xFF7A8B99)),
                      title: const Text(
                        'الوضع الليلي المريح',
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _isNightMode = val);
                      },
                    ),

                    // 8. حجم الخط
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'حجم خط المصحف',
                                style: TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text('${_fontSize.toInt()} نقطة'),
                            ],
                          ),
                          Slider(
                            value: _fontSize,
                            min: 17.0,
                            max: 30.0,
                            activeColor: ItqanColors.emerald,
                            onChanged: (val) {
                              setState(() => _fontSize = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFC79834)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 11),
      ),
      onTap: onTap,
    );
  }

  // ─── Modal Dialogs & Sheets ───────────────────────────────────────────────

  /// نافذة الذهاب إلى صفحة محددة
  void _showGoToPageDialog() {
    int target = _currentPage;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFDF8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'الذهاب إلى صفحة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.emerald,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الصفحة: $target',
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: target.toDouble(),
                    min: 1,
                    max: 604,
                    divisions: 603,
                    activeColor: ItqanColors.emerald,
                    onChanged: (val) {
                      setDialogState(() {
                        target = val.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _goToPage(target);
                  },
                  child: const Text('انتقال'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// نافذة التفسير المباشر
  void _showDirectTafsirSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final pageAsync = ref.watch(mushafPageDataProvider(_currentPage));

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBF7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'التفسير الميسر للصفحة الحالية',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: pageAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: ItqanColors.emerald)),
                      error: (e, _) => Center(child: Text('تعذر تحميل التفسير: $e')),
                      data: (pageData) {
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: pageData.verses.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final v = pageData.verses[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '﴿${v.textUthmani}﴾ [${v.verseKey}]',
                                  style: const TextStyle(
                                    fontFamily: 'NotoNaskhArabic',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ItqanColors.emeraldDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  v.translation.isNotEmpty
                                      ? v.translation
                                      : 'التفسير متاح عبر الاتصال بالشبكة لبيان معاني الآية ودلالتها الإيمانية.',
                                  style: const TextStyle(
                                    fontFamily: 'NotoNaskhArabic',
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// نافذة كلمة بكلمة
  void _showWordByWordSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFDFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'معاني الكلمات (كلمة بكلمة)',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.emerald,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'يمكنك النقر على أي كلمة أو آية لعرض ترجمتها اللفظية وتوضيح حكمها التجويدي مباشرة في الصفحة.',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(45),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تفعيل العرض التفاعلي للكلمات'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// البحث الصوتي
  void _startVoiceSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'جارٍ الاستماع للآية الكريمة صوتياً...',
          style: TextStyle(fontFamily: 'NotoNaskhArabic'),
        ),
        backgroundColor: ItqanColors.emerald,
      ),
    );
  }

  /// نافذة الترجمة
  void _showTranslationSheet() {
    _showDirectTafsirSheet();
  }

  /// قائمة الإجراءات عند النقر على آية محددة
  void _showAyahActionMenu(VerseOnPage verse) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFDF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الآية ${verse.ayahNumber} - سورة ${verse.surahNumber}',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.emerald,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '﴿${verse.textUthmani}﴾',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 15,
                  color: ItqanColors.ink,
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAyahActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'استماع',
                    onTap: () {
                      Navigator.pop(context);
                      _toggleAudio();
                    },
                  ),
                  _buildAyahActionButton(
                    icon: Icons.menu_book_rounded,
                    label: 'تفسير',
                    onTap: () {
                      Navigator.pop(context);
                      _showDirectTafsirSheet();
                    },
                  ),
                  _buildAyahActionButton(
                    icon: Icons.copy_rounded,
                    label: 'نسخ',
                    onTap: () {
                      Clipboard.setData(ClipboardData(
                          text: '﴿${verse.textUthmani}﴾ [${verse.verseKey}]'));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الآية')),
                      );
                    },
                  ),
                  _buildAyahActionButton(
                    icon: Icons.bookmark_add_rounded,
                    label: 'حفظ كمرجع',
                    onTap: () {
                      Navigator.pop(context);
                      _toggleBookmark();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAyahActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0x1AD4AF37),
              child: Icon(icon, color: ItqanColors.emerald, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
