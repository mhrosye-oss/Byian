import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';
import '../../../quran/models/ayah.dart';
import '../../../quran/services/quran_service.dart';
import '../../data/audio/audio_player_service.dart';

/// شاشة "احفظ معي" – التكرار الذكي والتثبيت مع تحكم صوتي متكامل وإخفاء النص
class MemorizationScreen extends ConsumerStatefulWidget {
  const MemorizationScreen({super.key});

  @override
  ConsumerState<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends ConsumerState<MemorizationScreen> {
  final QuranService _quranService = QuranService();
  final AudioPlayerService _audioService = AudioPlayerService();

  List<Surah> _surahs = [];
  Surah? _selectedSurah;
  int _startAyah = 1;
  int _endAyah = 1;

  List<Ayah> _verses = [];
  bool _isLoadingSurahs = true;
  bool _isLoadingVerses = false;
  String? _errorMessage;

  bool _hideText = false;
  final Set<int> _revealedAyahs = {}; // الآيات المكشوفة مؤقتاً عند الإخفاء

  int _repeatCount = 1; // 1, 3, 5, -1 (مستمر)
  int _currentPlayingIndex = -1;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupAudioListener();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  void _setupAudioListener() {
    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
        });

        if (state.processingState == ProcessingState.completed && _isPlaying) {
          _onAyahAudioCompleted();
        }
      }
    });
  }

  void _onAyahAudioCompleted() {
    if (_currentPlayingIndex >= 0 && _currentPlayingIndex < _verses.length - 1) {
      // الانتقال للآية التالية تلقائياً إذا كان ضمن نطاق
      _playVerseAtIndex(_currentPlayingIndex + 1);
    } else if (_repeatCount > 1 || _repeatCount == -1) {
      // إعادة التشغيل من البداية عند التكرار
      _playVerseAtIndex(0);
    } else {
      setState(() {
        _currentPlayingIndex = -1;
        _isPlaying = false;
      });
    }
  }

  Future<void> _initData() async {
    try {
      await _quranService.init();
      final surahs = await _quranService.getSurahs();
      if (!mounted) return;

      setState(() {
        _surahs = surahs;
        _isLoadingSurahs = false;
      });

      // محاولة استعادة آخر تقدم محفوظ
      await _restoreLastProgress(surahs);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSurahs = false;
          _errorMessage = 'تعذر تحميل بيانات السور من المصحف.';
        });
      }
    }
  }

  Future<void> _restoreLastProgress(List<Surah> surahs) async {
    try {
      final box = await Hive.openBox('quran_teacher_progress');
      final last = box.get('lastSession');
      if (last != null && last is Map && surahs.isNotEmpty) {
        final surahNum = last['surah'] as int? ?? 1;
        final start = last['startAyah'] as int? ?? 1;
        final end = last['endAyah'] as int? ?? 5;

        final found = surahs.firstWhere(
          (s) => s.number == surahNum,
          orElse: () => surahs.first,
        );

        setState(() {
          _selectedSurah = found;
          _startAyah = start.clamp(1, found.ayahCount);
          _endAyah = end.clamp(_startAyah, found.ayahCount);
        });

        await _loadVerses();
      } else if (surahs.isNotEmpty) {
        // الافتراضي سورة الفاتحة
        setState(() {
          _selectedSurah = surahs.first;
          _startAyah = 1;
          _endAyah = surahs.first.ayahCount.clamp(1, 7);
        });
        await _loadVerses();
      }
    } catch (_) {
      // في حال تعذر القراءة، نبدأ بالفاتحة
      if (surahs.isNotEmpty) {
        setState(() {
          _selectedSurah = surahs.first;
          _startAyah = 1;
          _endAyah = surahs.first.ayahCount;
        });
        await _loadVerses();
      }
    }
  }

  Future<void> _loadVerses() async {
    if (_selectedSurah == null) return;
    setState(() {
      _isLoadingVerses = true;
      _errorMessage = null;
      _currentPlayingIndex = -1;
      _revealedAyahs.clear();
    });

    try {
      final all = await _quranService.getAyahs(_selectedSurah!.number);
      final filtered = all
          .where((a) => a.ayahNumber >= _startAyah && a.ayahNumber <= _endAyah)
          .toList();

      if (mounted) {
        setState(() {
          _verses = filtered;
          _isLoadingVerses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVerses = false;
          _errorMessage = 'تعذر تحميل آيات السورة المحددة.';
        });
      }
    }
  }

  Future<void> _playVerseAtIndex(int index) async {
    if (index < 0 || index >= _verses.length) return;
    setState(() {
      _currentPlayingIndex = index;
    });

    try {
      final ayah = _verses[index];
      await _audioService.playAyah(ayah);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تشغيل تلاوة هذه الآية، تحقق من اتصال الإنترنت.'),
            backgroundColor: ItqanColors.roseGold,
          ),
        );
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      if (_currentPlayingIndex >= 0) {
        await _audioService.resume();
      } else if (_verses.isNotEmpty) {
        await _playVerseAtIndex(0);
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioService.stop();
    setState(() {
      _isPlaying = false;
      _currentPlayingIndex = -1;
    });
  }

  Future<void> _saveProgress(String masteryLevel) async {
    if (_selectedSurah == null || _verses.isEmpty) return;

    try {
      final box = await Hive.openBox('quran_teacher_progress');
      final sessionData = {
        'surah': _selectedSurah!.number,
        'surahName': _selectedSurah!.nameArabic,
        'startAyah': _startAyah,
        'endAyah': _endAyah,
        'verseCount': _verses.length,
        'masteryLevel': masteryLevel,
        'isRevision': false,
        'timestamp': DateTime.now().toIso8601String(),
        'nextReviewDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      // حفظ آخر جلسة للتلقائية
      await box.put('lastSession', sessionData);
      // إضافة إلى السجل التراكمي
      await box.add(sessionData);

      if (mounted) {
        Navigator.pop(context); // إغلاق نافذة المستوى
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل تقدمك في «${_selectedSurah!.nameArabic}» بنجاح! تقبل الله.'),
            backgroundColor: ItqanColors.emeraldDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ التقدم محلياً.'),
            backgroundColor: ItqanColors.roseGold,
          ),
        );
      }
    }
  }

  void _showSaveProgressDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تسجيل مستوى الحفظ',
                style: TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اختر مستوى إتقانك للآيات ($_startAyah - $_endAyah) من ${_selectedSurah?.nameArabic ?? ""}',
                style: const TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontSize: 13,
                  color: ItqanColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              _buildLevelButton(
                title: 'متقن ومثبت بنجاح',
                subtitle: 'أستطيع تلاوتها غيباً دون أخطاء',
                icon: Icons.check_circle_rounded,
                color: ItqanColors.emerald,
                onTap: () => _saveProgress('متقن'),
              ),
              const SizedBox(height: 10),
              _buildLevelButton(
                title: 'يحتاج إلى تثبيت ومراجعة',
                subtitle: 'حفظتها لكن أحتاج لترديدها وتأكيدها',
                icon: Icons.refresh_rounded,
                color: Colors.orange,
                onTap: () => _saveProgress('يحتاج تثبيت'),
              ),
              const SizedBox(height: 10),
              _buildLevelButton(
                title: 'قيد الحفظ والتكرار',
                subtitle: 'ما زلت في مرحلة الحفظ والتلقين',
                icon: Icons.hourglass_top_rounded,
                color: Colors.blue,
                onTap: () => _saveProgress('قيد الحفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 12,
                      color: ItqanColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اختر السورة الكريمة',
                  style: TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _surahs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final surah = _surahs[index];
                    final isSelected = surah.number == _selectedSurah?.number;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      selected: isSelected,
                      selectedTileColor: ItqanColors.emerald.withValues(alpha: 0.1),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected ? ItqanColors.emerald : ItqanColors.surface,
                        foregroundColor: isSelected ? Colors.white : ItqanColors.ink,
                        child: Text(
                          '${surah.number}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        surah.nameArabic,
                        style: const TextStyle(
                          fontFamily: ItqanTypography.arabicFont,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${surah.ayahCount} آية • ${surah.revelationPlace == 'makkah' ? "مكية" : "مدنية"}',
                        style: const TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: ItqanColors.emerald)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedSurah = surah;
                          _startAyah = 1;
                          _endAyah = surah.ayahCount.clamp(1, 5);
                        });
                        _loadVerses();
                      },
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: TeacherAppBar(
          title: 'احفظ معي',
          actions: [
            IconButton(
              tooltip: _hideText ? 'إظهار النص' : 'إخفاء النص للاختبار',
              icon: Icon(
                _hideText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: _hideText ? ItqanColors.roseGold : ItqanColors.emerald,
              ),
              onPressed: () {
                setState(() {
                  _hideText = !_hideText;
                  _revealedAyahs.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    content: Text(
                      _hideText
                          ? 'تم إخفاء النص لاختبار حفظك. يمكنك لمس أي آية لإظهارها مؤقتاً.'
                          : 'تم إظهار نص الآيات.',
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'تسجيل مستوى الحفظ',
              icon: const Icon(Icons.bookmark_add_rounded, color: ItqanColors.emerald),
              onPressed: _showSaveProgressDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoadingSurahs
              ? const TeacherLoadingWidget(message: 'جاري تحميل المصحف الشريف...')
              : _errorMessage != null
                  ? TeacherErrorState(message: _errorMessage!, onRetry: _initData)
                  : Column(
                      children: [
                        // شريط تحديد السورة ونطاق الآيات
                        _buildSelectionBar(),

                        // شريط التحكم بالصوت والتكرار
                        _buildAudioControlBar(),

                        // قائمة الآيات
                        Expanded(
                          child: _isLoadingVerses
                              ? const TeacherLoadingWidget(message: 'جاري جلب الآيات الكريمة...')
                              : _verses.isEmpty
                                  ? const TeacherEmptyState(
                                      title: 'لا توجد آيات',
                                      subtitle: 'حدد نطاق الآيات واضغط تحميل',
                                      icon: Icons.menu_book_rounded,
                                    )
                                  : _buildVersesList(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.ink.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // اختيار السورة
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showSurahPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ItqanColors.emerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ItqanColors.emerald.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: ItqanColors.emerald, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedSurah?.nameArabic ?? 'اختر السورة',
                            style: const TextStyle(
                              fontFamily: ItqanTypography.arabicFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ItqanColors.emeraldDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: ItqanColors.emerald),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _loadVerses,
                style: FilledButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text(
                  'عرض',
                  style: TextStyle(fontFamily: ItqanTypography.uiFont, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // تحديد الآية الأولى والأخيرة
          if (_selectedSurah != null)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'من آية:',
                        style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _startAyah,
                        isDense: true,
                        borderRadius: BorderRadius.circular(12),
                        items: List.generate(
                          _selectedSurah!.ayahCount,
                          (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _startAyah = val;
                              if (_endAyah < _startAyah) _endAyah = _startAyah;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'إلى آية:',
                        style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _endAyah,
                        isDense: true,
                        borderRadius: BorderRadius.circular(12),
                        items: List.generate(
                          _selectedSurah!.ayahCount - _startAyah + 1,
                          (i) => DropdownMenuItem(
                            value: _startAyah + i,
                            child: Text('${_startAyah + i}'),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _endAyah = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAudioControlBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // زر تشغيل / إيقاف
          IconButton.filledTonal(
            tooltip: _isPlaying ? 'إيقاف مؤقت' : 'تشغيل النطاق',
            style: IconButton.styleFrom(
              backgroundColor: ItqanColors.emerald.withValues(alpha: 0.15),
              foregroundColor: ItqanColors.emerald,
            ),
            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            onPressed: _toggleAudio,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'إيقاف كلي',
            icon: const Icon(Icons.stop_rounded, size: 22),
            onPressed: _stopAudio,
          ),
          const Spacer(),

          // خيار التكرار
          const Text(
            'التكرار:',
            style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 12),
          ),
          const SizedBox(width: 6),
          DropdownButton<int>(
            value: _repeatCount,
            isDense: true,
            borderRadius: BorderRadius.circular(12),
            items: const [
              DropdownMenuItem(value: 1, child: Text('مرة')),
              DropdownMenuItem(value: 3, child: Text('٣ مرات')),
              DropdownMenuItem(value: 5, child: Text('٥ مرات')),
              DropdownMenuItem(value: -1, child: Text('مستمر')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _repeatCount = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _verses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ayah = _verses[index];
        final isPlayingThis = _currentPlayingIndex == index && _isPlaying;
        final isHidden = _hideText && !_revealedAyahs.contains(ayah.ayahNumber);

        return Container(
          decoration: BoxDecoration(
            color: isPlayingThis
                ? ItqanColors.emerald.withValues(alpha: 0.08)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPlayingThis ? ItqanColors.emerald : Theme.of(context).dividerColor,
              width: isPlayingThis ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رأس الآية: رقم الآية وأزرار التفاعل
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPlayingThis
                            ? ItqanColors.emerald
                            : ItqanColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'آية ${ayah.ayahNumber}',
                        style: TextStyle(
                          fontFamily: ItqanTypography.uiFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPlayingThis ? Colors.white : ItqanColors.emerald,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_hideText)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: () {
                          setState(() {
                            if (_revealedAyahs.contains(ayah.ayahNumber)) {
                              _revealedAyahs.remove(ayah.ayahNumber);
                            } else {
                              _revealedAyahs.add(ayah.ayahNumber);
                            }
                          });
                        },
                        icon: Icon(
                          isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 16,
                          color: ItqanColors.roseGold,
                        ),
                        label: Text(
                          isHidden ? 'كشف الآية' : 'إخفاء',
                          style: const TextStyle(
                            fontFamily: ItqanTypography.uiFont,
                            fontSize: 12,
                            color: ItqanColors.roseGold,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: isPlayingThis ? 'إيقاف' : 'استمع للآية',
                      icon: Icon(
                        isPlayingThis ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: ItqanColors.emerald,
                        size: 32,
                      ),
                      onPressed: () {
                        if (isPlayingThis) {
                          _audioService.pause();
                        } else {
                          _playVerseAtIndex(index);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // نص الآية الكريمة
                InkWell(
                  onTap: _hideText
                      ? () {
                          setState(() {
                            if (_revealedAyahs.contains(ayah.ayahNumber)) {
                              _revealedAyahs.remove(ayah.ayahNumber);
                            } else {
                              _revealedAyahs.add(ayah.ayahNumber);
                            }
                          });
                        }
                      : null,
                  child: isHidden
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '•••••••••••••••••••••••••••••••••\n(انقر هنا لكشف نص الآية للتحقق من حفظك)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: ItqanTypography.uiFont,
                                fontSize: 13,
                                color: ItqanColors.muted,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          ayah.textUthmani,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: ItqanTypography.arabicFont,
                            fontSize: 22,
                            height: 2.1,
                            color: ItqanColors.ink,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
