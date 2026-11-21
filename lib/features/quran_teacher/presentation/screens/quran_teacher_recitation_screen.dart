import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';
import '../../../quran/models/ayah.dart';
import '../../../quran/services/quran_service.dart';
import '../../data/audio/audio_player_service.dart';
import '../../data/audio/engine/asr_engine.dart';
import '../../data/audio/engine/no_op_asr_engine.dart';

/// شاشة "سمّع لي" – تسجيل التلاوة، الاستماع إليها، والتحقق من الحفظ
class QuranTeacherRecitationScreen extends ConsumerStatefulWidget {
  const QuranTeacherRecitationScreen({super.key});

  @override
  ConsumerState<QuranTeacherRecitationScreen> createState() =>
      _QuranTeacherRecitationScreenState();
}

class _QuranTeacherRecitationScreenState
    extends ConsumerState<QuranTeacherRecitationScreen>
    with WidgetsBindingObserver {
  final QuranService _quranService = QuranService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayerService _audioPlaybackService = AudioPlayerService();
  final AsrEngine _asrEngine = NoOpAsrEngine();

  List<Surah> _surahs = [];
  Surah? _selectedSurah;
  int _targetStartAyah = 1;
  int _targetEndAyah = 1;
  List<Ayah> _targetAyahs = [];

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  String? _recordedFilePath;
  bool _isPlayingRecorded = false;
  bool _isAnalyzing = false;
  StreamSubscription<PlayerState>? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDisclaimerAndLoadSurahs();
    _setupPlaybackListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _isRecording) {
      _stopRecording();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _playbackSubscription?.cancel();
    unawaited(_disposeRecorder());
    _audioPlaybackService.dispose();
    super.dispose();
  }

  Future<void> _disposeRecorder() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {
        // The recorder may already have stopped because of an interruption.
      }
    }
    try {
      await _recorder.dispose();
    } catch (_) {
      // Disposal during platform teardown should not crash navigation.
    }
  }

  void _setupPlaybackListener() {
    _playbackSubscription = _audioPlaybackService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingRecorded = state.playing;
        });
      }
    });
  }

  Future<void> _checkDisclaimerAndLoadSurahs() async {
    try {
      final settingsBox = await Hive.openBox('settings');
      final seenDisclaimer = settingsBox.get('seen_recitation_disclaimer') == true;
      if (!seenDisclaimer && mounted) {
        Navigator.of(context).pushReplacementNamed('/recitation_intro');
        return;
      }

      await _quranService.init();
      final surahs = await _quranService.getSurahs();
      if (mounted) {
        setState(() {
          _surahs = surahs;
          if (surahs.isNotEmpty) {
            _selectedSurah = surahs.first;
            _targetStartAyah = 1;
            _targetEndAyah = surahs.first.ayahCount.clamp(1, 5);
          }
        });
        await _loadTargetAyahs();
      }
    } catch (_) {}
  }

  Future<void> _loadTargetAyahs() async {
    final surah = _selectedSurah;
    if (surah == null) return;
    try {
      final ayahs = await _quranService.getAyahs(surah.number);
      if (!mounted || _selectedSurah?.number != surah.number) return;
      setState(() {
        _targetAyahs = ayahs
            .where((ayah) => ayah.ayahNumber >= _targetStartAyah &&
                ayah.ayahNumber <= _targetEndAyah)
            .toList(growable: false);
      });
    } catch (_) {
      if (mounted) setState(() => _targetAyahs = []);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // إيقاف أي استماع سابق
    await _audioPlaybackService.stop();
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _recordedFilePath = null;
        _recordingSeconds = 0;
      });
    }

    // فحص إذن الميكروفون فقط عند الضغط
    var hasPermission = false;
    try {
      hasPermission = await _recorder.hasPermission();
    } catch (_) {
      // Permission state can fail on unsupported devices; report it as unavailable.
    }
    if (!mounted) return;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى منح إذن استخدام الميكروفون لتتمكن من التسميع والتسجيل.'),
          backgroundColor: ItqanColors.roseGold,
        ),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      if (!mounted) return;
      final path =
          '${tempDir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      if (!mounted) {
        try {
          await _recorder.stop();
        } catch (_) {
          // Navigation may dispose the recorder while platform recording starts.
        }
        return;
      }
      setState(() {
        _isRecording = true;
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر بدء التسجيل. تحقق من إذن الميكروفون وحاول مجدداً.'),
            backgroundColor: ItqanColors.roseGold,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
    } catch (_) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordedFilePath == null) return;
    if (_isPlayingRecorded) {
      await _audioPlaybackService.pause();
    } else {
      try {
        await _audioPlaybackService.playFilePath(_recordedFilePath!);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر تشغيل الملف الصوتي المسجل.'),
              backgroundColor: ItqanColors.roseGold,
            ),
          );
        }
      }
    }
  }

  Future<void> _analyzeRecitation() async {
    if (_recordedFilePath == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // قد يُرجع المحرك الحالي حالة عدم التوفر؛ لا نصطنع transcript أو تقييماً.
      final result = await _asrEngine.recognize(_recordedFilePath!);

      // لا نضيف جلسة التسميع إلى جدول المراجعة إلا بطلب صريح من شاشة النتيجة.
      final box = await Hive.openBox('quran_teacher_recitation');
      final timestamp = DateTime.now().toIso8601String();
      final selectedSurah = _selectedSurah;
      var expectedText = '';
      if (selectedSurah != null) {
        final ayahs = await _quranService.getAyahs(selectedSurah.number);
        expectedText = ayahs
            .where((ayah) => ayah.ayahNumber >= _targetStartAyah &&
                ayah.ayahNumber <= _targetEndAyah)
            .map((ayah) => ayah.textUthmani)
            .where((text) => text.isNotEmpty)
            .join(' ');
      }
      final recordData = {
        'surah': _selectedSurah?.number ?? 1,
        'surahName': _selectedSurah?.nameArabic ?? '',
        'startAyah': _targetStartAyah,
        'endAyah': _targetEndAyah,
        'audioPath': _recordedFilePath,
        'engineUnavailable': result.engineUnavailable,
        'transcript': result.transcript,
        'expectedText': result.expectedText ?? (expectedText.isEmpty ? null : expectedText),
        'timestamp': timestamp,
        'revisionScheduled': false,
      };
      await box.put('lastResult', recordData);
      await box.add(recordData);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      // الانتقال إلى شاشة النتيجة
      Navigator.of(context).pushNamed('/recitation_result');
    } catch (_) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر حفظ نتيجة الجلسة. حاول مجدداً.'),
            backgroundColor: ItqanColors.roseGold,
          ),
        );
      }
    }
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: TeacherAppBar(
          title: 'سمّع لي',
          actions: [
            IconButton(
              tooltip: 'تنويه التسميع',
              icon: const Icon(Icons.info_outline_rounded, color: ItqanColors.emerald),
              onPressed: () {
                Navigator.of(context).pushNamed('/recitation_intro');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                // اختيار السورة والآيات المستهدفة
                _buildTargetSelector(),

                const Spacer(),

                // مؤشر وأزرار التسجيل
                _buildRecordingSection(),

                const Spacer(),

                // قسم الاستماع والتحليل عند انتهاء التسجيل
                if (_recordedFilePath != null && !_isRecording)
                  _buildReviewSection()
                else
                  const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حدد المقطع المستهدف للتسميع:',
            style: TextStyle(
              fontFamily: ItqanTypography.uiFont,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ItqanColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<Surah>(
                  initialValue: _selectedSurah,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'السورة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _surahs.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.nameArabic, style: const TextStyle(fontFamily: ItqanTypography.arabicFont)),
                  )).toList(),
                  onChanged: (s) {
                    if (s != null) {
                      setState(() {
                        _selectedSurah = s;
                        _targetStartAyah = 1;
                        _targetEndAyah = s.ayahCount.clamp(1, 5);
                        _targetAyahs = [];
                      });
                      _loadTargetAyahs();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_selectedSurah != null) ...[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _targetStartAyah,
                    decoration: InputDecoration(
                      labelText: 'من آية',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: List.generate(
                      _selectedSurah!.ayahCount,
                      (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _targetStartAyah = val;
                          if (_targetEndAyah < _targetStartAyah) _targetEndAyah = _targetStartAyah;
                          _targetAyahs = [];
                        });
                        _loadTargetAyahs();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _targetEndAyah,
                    decoration: InputDecoration(
                      labelText: 'إلى آية',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: List.generate(
                      _selectedSurah!.ayahCount - _targetStartAyah + 1,
                      (i) => DropdownMenuItem(
                        value: _targetStartAyah + i,
                        child: Text('${_targetStartAyah + i}'),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _targetEndAyah = val);
                        _loadTargetAyahs();
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          if (_targetAyahs.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 142),
              child: SingleChildScrollView(
                child: Text(
                  _targetAyahs.map((ayah) => ayah.textUthmani).join(' '),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: ItqanTypography.arabicFont,
                    fontSize: 18,
                    height: 1.9,
                    color: ItqanColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Column(
      children: [
        // عداد الوقت
        Text(
          _formatTimer(_recordingSeconds),
          style: TextStyle(
            fontFamily: ItqanTypography.uiFont,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: _isRecording ? ItqanColors.roseGold : ItqanColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording
              ? 'جاري التسجيل... رتّل بهدوء ووضوح'
              : _recordedFilePath != null
                  ? 'تم اكتمال التسجيل، يمكنك الاستماع له وتحليله'
                  : 'اضغط على الميكروفون لبدء التسجيل',
          style: TextStyle(
            fontFamily: ItqanTypography.uiFont,
            fontSize: 13,
            color: _isRecording ? ItqanColors.roseGold : ItqanColors.muted,
          ),
        ),
        const SizedBox(height: 28),

        // زر التسجيل الرئيسي
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isRecording ? 104 : 96,
            height: _isRecording ? 104 : 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? ItqanColors.roseGold : ItqanColors.emerald,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? ItqanColors.roseGold : ItqanColors.emerald)
                      .withValues(alpha: 0.35),
                  blurRadius: _isRecording ? 24 : 14,
                  spreadRadius: _isRecording ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: _isPlayingRecorded ? 'إيقاف الاستماع' : 'استمع لتسجيلك',
                style: IconButton.styleFrom(
                  backgroundColor: ItqanColors.emerald.withValues(alpha: 0.15),
                  foregroundColor: ItqanColors.emerald,
                ),
                icon: Icon(_isPlayingRecorded ? Icons.pause_rounded : Icons.play_arrow_rounded),
                onPressed: _togglePlayback,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'استمع إلى تلاوتك المسجلة للتحقق من وضوح الصوت',
                  style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _startRecording,
                child: const Text(
                  'إعادة التسجيل',
                  style: TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    color: ItqanColors.roseGold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeRecitation,
              style: FilledButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_rounded, size: 20),
              label: Text(
                _isAnalyzing ? 'جاري التحقق من التسميع...' : 'تحليل التسميع وعرض النتيجة',
                style: const TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
