import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../ai/screens/ai_chat_screen.dart';

class PremiumMushafReader extends StatefulWidget {
  const PremiumMushafReader({super.key});

  @override
  State<PremiumMushafReader> createState() => _PremiumMushafReaderState();
}

class _PremiumMushafReaderState extends State<PremiumMushafReader> {
  bool _showTranslation = false;
  bool _isLoading = true;
  List<Ayah> _ayahs = [];
  
  // إعدادات القراءة
  double _arabicFontSize = 24.0;
  bool _isBookmarked = false;

  // متغيرات الصوت
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  // متغيرات اللف التلقائي
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false;
  Timer? _autoScrollTimer;

  final List<String> _fallbackTranslations = [
    "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
    "[All] praise is [due] to Allah, Lord of the worlds -",
    "The Entirely Merciful, the Especially Merciful,",
    "Sovereign of the Day of Recompense.",
    "It is You we worship and You we ask for help.",
    "Guide us to the straight path -",
    "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray."
  ];

  @override
  void initState() {
    super.initState();
    _loadSurah();
    _loadBookmarkStatus();
  }

  Future<void> _loadSurah() async {
    try {
      final quranService = QuranService();
      final data = await quranService.getAyahs(1);
      if (mounted) {
        setState(() {
          _ayahs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBookmarked = prefs.getBool('bookmark_surah_1') ?? false;
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBookmarked = !_isBookmarked;
      prefs.setBool('bookmark_surah_1', _isBookmarked);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isBookmarked ? 'تم حفظ الصفحة في المفضلة' : 'تم إزالة الصفحة من المفضلة')),
    );
  }

  void _shareSurah() {
    String fullText = _ayahs.map((a) => a.textUthmani).join(' ');
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ السورة كاملة للمشاركة')),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حجم الخط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 18),
                      Expanded(
                        child: Slider(
                          value: _arabicFontSize,
                          min: 18.0,
                          max: 40.0,
                          divisions: 22,
                          activeColor: const Color(0xFF1B5E20),
                          label: _arabicFontSize.round().toString(),
                          onChanged: (value) {
                            setState(() => _arabicFontSize = value);
                            setModalState(() {});
                          },
                        ),
                      ),
                      const Icon(Icons.text_fields, size: 28),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_player.audioSource == null) {
          await _player.setUrl('https://server8.mp3quran.net/afs/001.mp3');
        }
        await _player.play();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تشغيل الصوت: $e')));
      }
    }
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _autoScrollTimer?.cancel();
      setState(() => _isAutoScrolling = false);
    } else {
      setState(() => _isAutoScrolling = true);
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_scrollController.hasClients) {
          double currentOffset = _scrollController.offset;
          double maxExtent = _scrollController.position.maxScrollExtent;
          if (currentOffset < maxExtent) {
            _scrollController.jumpTo(currentOffset + 2.0);
          } else {
            _autoScrollTimer?.cancel();
            setState(() => _isAutoScrolling = false);
          }
        }
      });
    }
  }

  // بناء النص المتصل (الرسم العثماني المتصل)
  List<InlineSpan> _buildMushafText(ThemeData theme) {
    List<InlineSpan> spans = [];
    for (int i = 0; i < _ayahs.length; i++) {
      final ayah = _ayahs[i];
      final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

      // النص القرآني
      spans.add(TextSpan(
        text: '${ayah.textUthmani} ',
        style: TextStyle(fontSize: _arabicFontSize, fontFamily: 'Amiri', height: 2.0, color: textColor),
      ));
      
      // رقم الآية (بشكل زخرفي)
      spans.add(TextSpan(
        text: '﴿${ayah.ayahNumber}﴾ ',
        style: TextStyle(fontSize: _arabicFontSize - 2, color: const Color(0xFF1B5E20), fontFamily: 'Amiri'),
      ));
    }
    return spans;
  }

  @override
  void dispose() {
    _player.dispose();
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTextColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'سُورَةُ الفَاتِحَة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri', color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // عرض المصحف كصفحة متصلة
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text.rich(
                      TextSpan(children: _buildMushafText(theme)),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  
                  // عرض الترجمة (إذا كانت مفعلة)
                  if (_showTranslation) ...[
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),
                    ..._ayahs.map((ayah) {
                      int index = int.tryParse(ayah.ayahNumber.toString()) ?? 1;
                      String trans = (ayah.translation != null && ayah.translation!.isNotEmpty) 
                          ? ayah.translation! 
                          : (index <= _fallbackTranslations.length ? _fallbackTranslations[index - 1] : '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '${ayah.ayahNumber}. $trans',
                          textAlign: TextAlign.left,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontSize: 16, color: subTextColor, height: 1.5),
                        ),
                      );
                    }).toList(),
                  ]
                ],
              ),
            ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomIcon(context, _isPlaying ? Icons.pause_rounded : Icons.headphones_rounded, _isPlaying ? 'إيقاف' : 'سماع', const Color(0xFF1B5E20), _toggleAudio),
            _buildBottomIcon(context, Icons.smart_toy_rounded, 'اسأل AI', const Color(0xFF1B5E20), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
            }),
            _buildBottomIcon(context, _isAutoScrolling ? Icons.pause_circle_outline_rounded : Icons.swap_vert_rounded, _isAutoScrolling ? 'إيقاف' : 'لف تلقائي', _isAutoScrolling ? const Color(0xFF1B5E20) : subTextColor, _toggleAutoScroll),
            _buildBottomIcon(context, Icons.share_rounded, 'مشاركة', subTextColor, _shareSurah),
            GestureDetector(
              onTap: () => setState(() => _showTranslation = !_showTranslation),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _showTranslation ? const Color(0xFF1B5E20).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.translate_rounded, color: _showTranslation ? const Color(0xFF1B5E20) : subTextColor, size: 22),
                    const SizedBox(height: 4),
                    Text('الترجمة', style: TextStyle(fontSize: 9, color: _showTranslation ? const Color(0xFF1B5E20) : subTextColor)),
                  ],
                ),
              ),
            ),
            _buildBottomIcon(context, _isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded, 'حفظ', _isBookmarked ? const Color(0xFF1B5E20) : subTextColor, _toggleBookmark),
            _buildBottomIcon(context, Icons.more_horiz_rounded, 'مزيد', subTextColor, _showMoreOptions),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIcon(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }
}
