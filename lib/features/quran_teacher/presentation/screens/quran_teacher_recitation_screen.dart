import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    extends ConsumerState<QuranTeacherRecitationScreen> {
  final QuranService _quranService = QuranService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayerService _audioPlaybackService = AudioPlayerService();
  final AsrEngine _asrEngine = NoOpAsrEngine();

  List<Surah> _surahs = [];
  Surah? _selectedSurah;
  int _targetStartAyah = 1;
  int _targetEndAyah = 1;

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  String? _recordedFilePath;
  bool _isPlayingRecorded = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _checkDisclaimerAndLoadSurahs();
    _setupPlaybackListener();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _audioPlaybackService.dispose();
    super.dispose();
  }

  void _setupPlaybackListener() {
    _audioPlaybackService.playerStateStream.listen((state) {
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
      }
    } catch (_) {}
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

    // فحص إذن الميكروفون فقط عند الضغط
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
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

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _recordedFilePath = null;
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء بدء التسجيل: $e'),
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
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
    } catch (e) {
      setState(() => _isRecording = false);
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
      // استدعاء محرك ASR الحقيقي
      final result = await _asrEngine.recognize(_recordedFilePath!);

      // حفظ جلسة التسميع في Hive
      final box = await Hive.openBox('quran_teacher_recitation');
      final recordData = {
        'surah': _selectedSurah?.number ?? 1,
        'surahName': _selectedSurah?.nameArabic ?? '',
        'startAyah': _targetStartAyah,
        'endAyah': _targetEndAyah,
        'audioPath': _recordedFilePath,
        'engineUnavailable': result.engineUnavailable,
        'transcript': result.transcript,
        'expectedText': result.expectedText ?? 'تلاوة ${_selectedSurah?.nameArabic} الآيات ($_targetStartAyah - $_targetEndAyah)',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await box.put('lastResult', recordData);
      await box.add(recordData);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      // الانتقال إلى شاشة النتيجة
      Navigator.of(context).pushNamed('/recitation_result');
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إتمام التحليل: $e'),
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
                      });
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
                        });
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
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
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
