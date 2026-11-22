import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';
import '../../../quran/services/quran_service.dart';
import '../../data/audio/audio_player_service.dart';
import '../../domain/services/recitation_matcher.dart';

/// شاشة عرض نتيجة التسميع
class RecitationResultScreen extends ConsumerStatefulWidget {
  const RecitationResultScreen({super.key});

  @override
  ConsumerState<RecitationResultScreen> createState() =>
      _RecitationResultScreenState();
}

class _RecitationResultScreenState
    extends ConsumerState<RecitationResultScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final SpeechToText _speech = SpeechToText();
  final QuranService _quranService = QuranService();
  static const RecitationMatcher _matcher = RecitationMatcher();
  bool _isPlaying = false;
  bool _isListening = false;
  Map<String, dynamic>? _resultData;
  String _expectedText = '';
  String _recognizedText = '';
  String? _asrError;
  RecitationComparison? _comparison;
  bool _isLoading = true;
  bool _savedToRevision = false;
  StreamSubscription<PlayerState>? _playbackSubscription;
  Timer? _recognitionTimer;

  @override
  void initState() {
    super.initState();
    _loadResult();
    _playbackSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _recognitionTimer?.cancel();
    if (_speech.isListening) unawaited(_speech.cancel());
    _playbackSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadResult() async {
    try {
      final box = await Hive.openBox('quran_teacher_recitation');
      final last = box.get('lastResult');
      if (last != null && last is Map) {
        final data = Map<String, dynamic>.from(last);
        if (!mounted) return;
        setState(() {
          _resultData = data;
          _savedToRevision = _resultData!['revisionScheduled'] == true;
          _isLoading = false;
        });
        await _loadExpectedText(data);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExpectedText(Map<String, dynamic> data) async {
    final surah = (data['surah'] as num?)?.toInt();
    final start = (data['startAyah'] as num?)?.toInt();
    final end = (data['endAyah'] as num?)?.toInt();
    if (surah == null || start == null || end == null || start > end) {
      if (mounted) setState(() => _asrError = 'تعذر تحديد الآيات المستهدفة.');
      return;
    }
    try {
      await _quranService.init();
      final ayahs = await _quranService.getAyahs(surah);
      final expected = ayahs
          .where((ayah) => ayah.ayahNumber >= start && ayah.ayahNumber <= end)
          .map((ayah) => ayah.textUthmani)
          .join(' ');
      if (expected.isEmpty) throw StateError('لا يوجد نص محلي للآيات المحددة.');
      if (mounted) setState(() => _expectedText = expected);
    } catch (error) {
      if (mounted)
        setState(() => _asrError = 'تعذر تحميل النص القرآني المحلي: $error');
    }
  }

  Future<void> _toggleLocalRecognition() async {
    if (_isListening || _speech.isListening) {
      await _stopLocalRecognition();
      return;
    }
    if (_expectedText.isEmpty) {
      _showMessage(_asrError ?? 'لم يُحمّل النص المحلي للمقطع بعد.');
      return;
    }

    setState(() {
      _asrError = null;
      _recognizedText = '';
      _comparison = null;
      _isListening = true;
    });
    try {
      await _audioPlayer.stop();
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == SpeechToText.listeningStatus) {
            setState(() => _isListening = true);
          } else if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            setState(() => _isListening = false);
            _recognitionTimer?.cancel();
            if (_recognizedText.trim().isNotEmpty) _compareRecognizedText();
          }
        },
        onError: (error) {
          if (!mounted) return;
          _recognitionTimer?.cancel();
          setState(() {
            _isListening = false;
            _asrError = 'تعذر التعرف على الكلام: ${error.errorMsg}';
          });
        },
      );
      if (!available) {
        throw StateError('خدمة التعرف الصوتي أو إذن الميكروفون غير متاح.');
      }

      final locales = await _speech.locales();
      final arabicLocales = locales.where((locale) {
        final id = locale.localeId.toLowerCase().replaceAll('_', '-');
        return id == 'ar' || id.startsWith('ar-');
      }).toList(growable: false);
      if (arabicLocales.isEmpty) {
        throw StateError(
          'لا توجد لغة عربية مدعومة في خدمة التعرف على هذا الجهاز.',
        );
      }
      final locale = arabicLocales.firstWhere(
        (item) => item.localeId.toLowerCase().replaceAll('_', '-') == 'ar-sa',
        orElse: () => arabicLocales.first,
      );

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _recognizedText = result.recognizedWords.trim());
          if (result.finalResult) {
            _recognitionTimer?.cancel();
            setState(() => _isListening = false);
            _compareRecognizedText();
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: locale.localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          onDevice: true,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      if (!mounted) return;
      setState(() => _isListening = true);
      _recognitionTimer?.cancel();
      _recognitionTimer = Timer(const Duration(seconds: 47), () {
        if (_isListening) unawaited(_stopLocalRecognition());
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _asrError = 'تعذر بدء التعرف الصوتي المحلي: $error';
      });
    }
  }

  Future<void> _stopLocalRecognition() async {
    _recognitionTimer?.cancel();
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (error) {
      if (mounted)
        setState(() => _asrError = 'تعذر إيقاف التعرف الصوتي: $error');
    }
    if (!mounted) return;
    setState(() => _isListening = false);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _compareRecognizedText();
  }

  void _compareRecognizedText() {
    final transcript = _recognizedText.trim();
    if (!mounted || transcript.isEmpty || _expectedText.isEmpty) return;
    final comparison = _matcher.compare(
      expectedText: _expectedText,
      recognizedText: transcript,
    );
    setState(() => _comparison = comparison);
    unawaited(_saveAsrResult(transcript, comparison));
  }

  Future<void> _saveAsrResult(
    String transcript,
    RecitationComparison comparison,
  ) async {
    try {
      final box = await Hive.openBox('quran_teacher_recitation');
      final data = _resultData;
      if (data == null) return;
      data['transcript'] = transcript;
      data['expectedText'] = _expectedText;
      data['accuracyPercent'] = comparison.accuracyPercent;
      data['engineUnavailable'] = false;
      await box.put('lastResult', data);
    } catch (error) {
      debugPrint('Failed to save local recitation analysis: $error');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _buildLocalAsrCard() {
    final comparison = _comparison;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ItqanColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مراجعة التلاوة بالتعرف الصوتي',
            style: TextStyle(
              fontFamily: ItqanTypography.uiFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ItqanColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'أعد قراءة الآيات المستهدفة في الميكروفون. سيقارن التطبيق الكلمات بالنص القرآني المحفوظ على الجهاز.',
            style: TextStyle(
              fontFamily: ItqanTypography.uiFont,
              fontSize: 12.5,
              height: 1.5,
              color: ItqanColors.inkSoft,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _toggleLocalRecognition,
            icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded),
            label: Text(
              _isListening
                  ? 'إيقاف الاستماع وعرض النتيجة'
                  : 'ابدأ التلاوة للتحليل',
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
                  _isListening ? ItqanColors.roseGold : ItqanColors.emerald,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_isListening) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: ItqanColors.emerald),
            const SizedBox(height: 8),
            const Text(
              'جارٍ الاستماع بالعربية… أوقفه عند انتهاء التلاوة.',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 12, color: ItqanColors.inkSoft),
            ),
          ],
          if (_asrError != null) ...[
            const SizedBox(height: 10),
            Text(
              _asrError!,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: ItqanColors.error, fontSize: 12),
            ),
          ],
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'النص الذي تعرّف عليه الجهاز:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _recognizedText,
              textDirection: TextDirection.rtl,
              style: const TextStyle(height: 1.6, fontSize: 14),
            ),
          ],
          if (comparison != null) ...[
            const SizedBox(height: 14),
            Text(
              'دقة مطابقة الكلمات: ${comparison.accuracyPercent.round()}%',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: ItqanColors.emeraldDark,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              textDirection: TextDirection.rtl,
              spacing: 6,
              runSpacing: 6,
              children: comparison.words.map((word) {
                final isCorrect = word.isCorrect;
                final label = word.expectedWord ?? word.recognizedWord ?? '';
                final color = isCorrect ? Colors.green : Colors.red;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isCorrect
                              ? Colors.green.shade800
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isCorrect && word.expectedWord != null)
                        Text(
                          word.recognizedWord ?? 'لم تُلتقط',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'المطابقة تقديرية وليست تقييمًا للتجويد. يطلب التطبيق المعالجة on-device، لكن دعم العربية دون اتصال يعتمد على محرك النظام وإعداداته، وقد يستخدم النظام الشبكة حسب الجهاز.',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: ItqanColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAudio() async {
    final path = _resultData?['audioPath'] as String?;
    if (path == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        await _audioPlayer.playFilePath(path);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر تشغيل التسجيل الصوتي.'),
              backgroundColor: ItqanColors.roseGold,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveToRevisionSchedule() async {
    if (_resultData == null || _savedToRevision) return;
    try {
      final progressBox = await Hive.openBox('quran_teacher_progress');
      final sessionData = {
        'surah': _resultData!['surah'],
        'surahName': _resultData!['surahName'],
        'startAyah': _resultData!['startAyah'],
        'endAyah': _resultData!['endAyah'],
        'verseCount': ((_resultData!['endAyah'] as int? ?? 1) -
            (_resultData!['startAyah'] as int? ?? 1) +
            1),
        'masteryLevel': 'تسميع صوتي',
        'isRevision': true,
        'timestamp': DateTime.now().toIso8601String(),
        'nextReviewDate':
            DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      };
      await progressBox.add(sessionData);
      final resultBox = await Hive.openBox('quran_teacher_recitation');
      _resultData!['revisionScheduled'] = true;
      await resultBox.put('lastResult', _resultData);

      if (mounted) {
        setState(() => _savedToRevision = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة هذا المقطع إلى جدول مراجعتك بنجاح!'),
            backgroundColor: ItqanColors.emeraldDark,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const TeacherAppBar(title: 'نتيجة التسميع'),
        body: SafeArea(
          child: _isLoading
              ? const TeacherLoadingWidget(
                  message: 'جاري تحميل تفاصيل التسميع...',
                )
              : _resultData == null
                  ? const TeacherEmptyState(
                      title: 'لا توجد نتائج سابقة',
                      subtitle: 'قم بتسجيل تلاوتك في شاشة "سمّع لي" أولاً',
                      icon: Icons.mic_none_rounded,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // بطاقة المقطع المستهدف
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: ItqanColors.emerald.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark_added_rounded,
                                      color: ItqanColors.emerald,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'سورة ${_resultData!["surahName"] ?? ""}',
                                          style: const TextStyle(
                                            fontFamily:
                                                ItqanTypography.arabicFont,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: ItqanColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'الآيات من ${_resultData!["startAyah"]} إلى ${_resultData!["endAyah"]}',
                                          style: const TextStyle(
                                            fontFamily: ItqanTypography.uiFont,
                                            fontSize: 13,
                                            color: ItqanColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // شريط الاستماع للتسجيل
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: ItqanColors.emerald.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    IconButton.filled(
                                      style: IconButton.styleFrom(
                                        backgroundColor: ItqanColors.emerald,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                      onPressed: _toggleAudio,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isPlaying
                                            ? 'إيقاف الاستماع'
                                            : 'استمع لتسجيلك الصوتي',
                                        style: TextStyle(
                                          fontFamily: ItqanTypography.uiFont,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: ItqanColors.emeraldDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildLocalAsrCard(),

                        const SizedBox(height: 24),

                        // أزرار الإجراءات
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/teacher_recitation');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: ItqanColors.emerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: const Text(
                            'تسميع مقطع آخر أو إعادة المحاولة',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed:
                              _savedToRevision ? null : _saveToRevisionSchedule,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ItqanColors.emerald,
                            side: const BorderSide(color: ItqanColors.emerald),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(
                            _savedToRevision
                                ? 'المقطع مضاف إلى جدول المراجعة'
                                : 'إضافة المقطع لجدول المراجعة التراكمية',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'العودة إلى رئيسية المعلّم',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              color: ItqanColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
