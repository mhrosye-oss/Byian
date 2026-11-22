import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';
import '../../data/audio/audio_player_service.dart';

/// شاشة عرض نتيجة التسميع
class RecitationResultScreen extends ConsumerStatefulWidget {
  const RecitationResultScreen({super.key});

  @override
  ConsumerState<RecitationResultScreen> createState() =>
      _RecitationResultScreenState();
}

class _RecitationResultScreenState extends ConsumerState<RecitationResultScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  bool _isPlaying = false;
  Map<String, dynamic>? _resultData;
  bool _isLoading = true;
  bool _savedToRevision = false;
  StreamSubscription<PlayerState>? _playbackSubscription;

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
    _playbackSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadResult() async {
    try {
      final box = await Hive.openBox('quran_teacher_recitation');
      final last = box.get('lastResult');
      if (last != null && last is Map) {
        setState(() {
          _resultData = Map<String, dynamic>.from(last);
          _savedToRevision = _resultData!['revisionScheduled'] == true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
        'verseCount': ((_resultData!['endAyah'] as int? ?? 1) - (_resultData!['startAyah'] as int? ?? 1) + 1),
        'masteryLevel': 'تسميع صوتي',
        'isRevision': true,
        'timestamp': DateTime.now().toIso8601String(),
        'nextReviewDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
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
              ? const TeacherLoadingWidget(message: 'جاري تحميل تفاصيل التسميع...')
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
                            border: Border.all(color: Theme.of(context).dividerColor),
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
                                      color: ItqanColors.emerald.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.bookmark_added_rounded, color: ItqanColors.emerald, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'سورة ${_resultData!["surahName"] ?? ""}',
                                          style: const TextStyle(
                                            fontFamily: ItqanTypography.arabicFont,
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: ItqanColors.emerald.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    IconButton.filled(
                                      style: IconButton.styleFrom(
                                        backgroundColor: ItqanColors.emerald,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
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

                        // حالة محرك التحليل ASR (بكل شفافية وأمانة)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_rounded, color: Colors.amber, size: 26),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'حالة التحليل الصوتي الذكي (ASR)',
                                      style: TextStyle(
                                        fontFamily: ItqanTypography.uiFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'تم تسجيل وحفظ تلاوتك بنجاح. محرك التحليل الآلي للكلمات القرآنية قيد المعايرة والتطوير في هذه النسخة، ولن نصدر أحكاماً قطعية غير دقيقة على صحة تلاوتك التزاماً بالأمانة العلمية لكتاب الله.',
                                      style: TextStyle(
                                        fontFamily: ItqanTypography.uiFont,
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: Colors.brown,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // أزرار الإجراءات
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/teacher_recitation');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: ItqanColors.emerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: const Text(
                            'تسميع مقطع آخر أو إعادة المحاولة',
                            style: TextStyle(fontFamily: ItqanTypography.uiFont, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _savedToRevision ? null : _saveToRevisionSchedule,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ItqanColors.emerald,
                            side: const BorderSide(color: ItqanColors.emerald),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text(
                            _savedToRevision
                                ? 'المقطع مضاف إلى جدول المراجعة'
                                : 'إضافة المقطع لجدول المراجعة التراكمية',
                            style: TextStyle(fontFamily: ItqanTypography.uiFont, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'العودة إلى رئيسية المعلّم',
                            style: TextStyle(fontFamily: ItqanTypography.uiFont, color: ItqanColors.muted),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
