import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../recitation/recitation_screen.dart';
import '../models/ayah.dart';
import '../services/arabic_normalizer.dart';
import '../services/quran_service.dart';

class QuranSearchScreen extends StatefulWidget {
  final QuranService service;

  const QuranSearchScreen({super.key, required this.service});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  Future<List<Ayah>>? _results;
  String _submittedQuery = '';
  String _recognizedText = '';
  String? _speechError;
  bool _speechReady = false;
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    if (_isListening) _speech.cancel();
    super.dispose();
  }

  Future<List<Ayah>> _search(String query) async {
    await widget.service.init();
    return widget.service.searchAyahs(query);
  }

  void _submit(String rawQuery) {
    final query = rawQuery.trim();
    if (ArabicNormalizer.normalize(query).isEmpty) return;
    setState(() {
      _submittedQuery = query;
      _results = _search(query);
    });
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() {
      _speechError = null;
      _recognizedText = '';
    });
    try {
      if (!_speechReady) {
        final available = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            setState(
                () => _isListening = status == SpeechToText.listeningStatus);
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _speechError = 'تعذر التعرف على الكلام: ${error.errorMsg}';
            });
          },
        );
        _speechReady = available;
      }
      if (!_speechReady) {
        setState(() {
          _speechError =
              'خدمة التعرف الصوتي غير متاحة. تحقق من إذن الميكروفون وإعدادات جهازك.';
        });
        return;
      }

      final locales = await _speech.locales();
      final arabicLocales = locales.where((locale) {
        final normalized = locale.localeId.toLowerCase().replaceAll('_', '-');
        return normalized == 'ar' || normalized.startsWith('ar-');
      });
      if (arabicLocales.isEmpty) {
        setState(() {
          _speechError =
              'لا توجد لغة عربية مثبتة لخدمة التعرف الصوتي على هذا الجهاز.';
        });
        return;
      }
      final locale = arabicLocales.firstWhere(
        (item) => item.localeId.toLowerCase().replaceAll('_', '-') == 'ar-sa',
        orElse: () => arabicLocales.first,
      );

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final recognized = result.recognizedWords.trim();
          setState(() {
            _recognizedText = recognized;
            if (recognized.isNotEmpty) {
              _controller.value = TextEditingValue(
                text: recognized,
                selection: TextSelection.collapsed(offset: recognized.length),
              );
            }
            if (result.finalResult) _isListening = false;
          });
        },
        listenOptions: SpeechListenOptions(
          localeId: locale.localeId,
          listenMode: ListenMode.search,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      if (mounted) setState(() => _isListening = _speech.isListening);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _speechError = 'تعذر بدء البحث الصوتي: $error';
      });
    }
  }

  TextSpan _highlight(String text, String query) {
    const style = TextStyle(
      fontFamily: 'NotoNaskhArabic',
      color: ItqanColors.ink,
      fontSize: 25,
      height: 1.9,
    );
    final ranges = ArabicNormalizer.matches(text, query);
    if (ranges.isEmpty) return TextSpan(text: text, style: style);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: const TextStyle(
          color: ItqanColors.ink,
          backgroundColor: Color(0x33B76E79),
          fontWeight: FontWeight.w800,
        ),
      ));
      cursor = range.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(style: style, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        title: const Text('البحث في القرآن', style: ItqanTypography.heading2),
        backgroundColor: ItqanColors.cream,
        foregroundColor: ItqanColors.ink,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(ItqanSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submit,
                  onChanged: (_) => setState(() {}),
                  style: ItqanTypography.body.copyWith(color: ItqanColors.ink),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن كلمة أو عبارة…',
                    hintStyle: ItqanTypography.caption,
                    filled: true,
                    fillColor: ItqanColors.surface,
                    prefixIcon: IconButton(
                      tooltip: 'بحث',
                      onPressed: () => _submit(_controller.text),
                      icon: const Icon(Icons.search_rounded,
                          color: ItqanColors.emerald),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                              _isListening ? 'إيقاف الاستماع' : 'بحث صوتي عربي',
                          onPressed: _toggleVoiceSearch,
                          icon: Icon(
                            _isListening
                                ? Icons.stop_circle_rounded
                                : Icons.mic_rounded,
                            color: _isListening
                                ? ItqanColors.roseGold
                                : ItqanColors.emerald,
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            tooltip: 'مسح',
                            onPressed: () => setState(() {
                              _controller.clear();
                              _results = null;
                              _submittedQuery = '';
                              _recognizedText = '';
                              _speechError = null;
                            }),
                            icon: const Icon(Icons.close_rounded,
                                color: ItqanColors.muted),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ItqanSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'يمكنك الكتابة أو الإملاء بالعربية. لن يُحفظ التسجيل الصوتي.',
                    style: ItqanTypography.caption,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (_isListening) ...[
                  const SizedBox(height: ItqanSpacing.sm),
                  const LinearProgressIndicator(color: ItqanColors.roseGold),
                  const SizedBox(height: ItqanSpacing.xs),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'جارٍ الاستماع… أوقفه عند الانتهاء، ثم راجع النص واضغط بحث.',
                      style: TextStyle(color: ItqanColors.roseGold),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
                if (_speechError != null) ...[
                  const SizedBox(height: ItqanSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(ItqanSpacing.sm),
                    decoration: BoxDecoration(
                      color: ItqanColors.roseGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ItqanRadius.sm),
                    ),
                    child: Text(
                      _speechError!,
                      style: ItqanTypography.caption.copyWith(
                        color: ItqanColors.ink,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
                if (_recognizedText.isNotEmpty) ...[
                  const SizedBox(height: ItqanSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'النص المتعرف عليه — راجعه وعدّله قبل البحث:',
                      style: ItqanTypography.caption,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final future = _results;
    if (future == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ItqanSpacing.lg),
          child: Text(
            'اكتب كلمة أو عبارة للعثور على آيات المصحف المطابقة بلا اعتبار للتشكيل. يعمل البحث النصي دون اتصال.',
            style: ItqanTypography.caption,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return FutureBuilder<List<Ayah>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ItqanColors.emerald),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(ItqanSpacing.lg),
              child: Text(
                'تعذر تنفيذ البحث: ${snapshot.error}',
                style: ItqanTypography.body.copyWith(color: ItqanColors.error),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        }

        final ayahs = snapshot.data ?? const <Ayah>[];
        if (ayahs.isEmpty) {
          return const Center(
            child: Text('لا توجد آيات مطابقة.',
                style: ItqanTypography.body, textDirection: TextDirection.rtl),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            ItqanSpacing.md,
            ItqanSpacing.xs,
            ItqanSpacing.md,
            ItqanSpacing.xl,
          ),
          itemCount: ayahs.length,
          separatorBuilder: (_, __) => const SizedBox(height: ItqanSpacing.sm),
          itemBuilder: (context, index) {
            final ayah = ayahs[index];
            return Material(
              color: ItqanColors.surface,
              borderRadius: BorderRadius.circular(ItqanRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(ItqanRadius.md),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecitationScreen(
                      ayah: ayah,
                      surahName: 'سورة ${ayah.surahNumber}',
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ItqanColors.roseGold.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(ItqanRadius.full),
                          ),
                          child: Text(
                            'سورة ${ayah.surahNumber} · الآية ${ayah.ayahNumber}',
                            style: const TextStyle(
                              color: ItqanColors.emerald,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      const SizedBox(height: ItqanSpacing.sm),
                      Text.rich(
                        _highlight(ayah.textUthmani, _submittedQuery),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.headphones_rounded,
                            size: 18, color: ItqanColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
