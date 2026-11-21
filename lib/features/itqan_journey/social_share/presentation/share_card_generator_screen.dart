import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/itqan_points_icon.dart';
import '../../referral/services/referral_service.dart';

enum ShareCardType {
  quranAyah,
  hadith,
  dhikr,
  dua,
  achievement,
  badge,
  level,
  invitation,
}

extension ShareCardTypeX on ShareCardType {
  String get title {
    switch (this) {
      case ShareCardType.quranAyah:
        return 'آية قرآنية';
      case ShareCardType.hadith:
        return 'حديث شريف';
      case ShareCardType.dhikr:
        return 'ذكر مبارك';
      case ShareCardType.dua:
        return 'دعاء مأثور';
      case ShareCardType.achievement:
        return 'إنجاز رحلتي';
      case ShareCardType.badge:
        return 'وسام إتقان';
      case ShareCardType.level:
        return 'المستوى المحقق';
      case ShareCardType.invitation:
        return 'بطاقة دعوة';
    }
  }

  IconData get icon {
    switch (this) {
      case ShareCardType.quranAyah:
        return Icons.auto_stories_rounded;
      case ShareCardType.hadith:
        return Icons.format_quote_rounded;
      case ShareCardType.dhikr:
        return Icons.spa_rounded;
      case ShareCardType.dua:
        return Icons.favorite_rounded;
      case ShareCardType.achievement:
        return Icons.emoji_events_rounded;
      case ShareCardType.badge:
        return Icons.military_tech_rounded;
      case ShareCardType.level:
        return Icons.star_rounded;
      case ShareCardType.invitation:
        return Icons.card_giftcard_rounded;
    }
  }
}

class ShareCardGeneratorScreen extends StatefulWidget {
  final ShareCardType initialType;
  final String? initialText;
  final String? initialSubtitle;

  const ShareCardGeneratorScreen({
    super.key,
    this.initialType = ShareCardType.quranAyah,
    this.initialText,
    this.initialSubtitle,
  });

  @override
  State<ShareCardGeneratorScreen> createState() => _ShareCardGeneratorScreenState();
}

class _ShareCardGeneratorScreenState extends State<ShareCardGeneratorScreen> {
  final GlobalKey _cardKey = GlobalKey();
  late ShareCardType _selectedType;
  late TextEditingController _textController;
  late TextEditingController _subtitleController;
  String _referralCode = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _textController = TextEditingController(text: widget.initialText ?? _defaultTextFor(_selectedType));
    _subtitleController = TextEditingController(text: widget.initialSubtitle ?? _defaultSubtitleFor(_selectedType));
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final code = await ReferralService.getOrCreateMyReferralCode();
    if (mounted) setState(() => _referralCode = code);
  }

  @override
  void dispose() {
    _textController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  String _defaultTextFor(ShareCardType type) {
    switch (type) {
      case ShareCardType.quranAyah:
        return '﴿ وَقُل رَّبِّ زِدْنِي عِلْمًا ﴾';
      case ShareCardType.hadith:
        return '«إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ»';
      case ShareCardType.dhikr:
        return 'سبحان الله وبحمده، سبحان الله العظيم';
      case ShareCardType.dua:
        return 'اللهم إني أسألك علماً نافعاً، ورزقاً طيباً، وعملاً متقبلاً';
      case ShareCardType.achievement:
        return 'بفضل الله أتممت وردي اليومي واستمرارية القراءة في رحلة إتقان';
      case ShareCardType.badge:
        return 'حصلت على وسام «رفيق القرآن» في تطبيق إتقان';
      case ShareCardType.level:
        return 'وصلت إلى المستوى الخامس في رحلة إتقان الإيمانية';
      case ShareCardType.invitation:
        return 'يسرني دعوتك لبدء رحلتك الإيمانية معي في تطبيق إتقان';
    }
  }

  String _defaultSubtitleFor(ShareCardType type) {
    switch (type) {
      case ShareCardType.quranAyah:
        return 'سورة طه - الآية 114';
      case ShareCardType.hadith:
        return 'صحيح الجامع - حديث شريف';
      case ShareCardType.dhikr:
        return 'أذكار الصباح والمساء';
      case ShareCardType.dua:
        return 'دعاء نبوي شريف';
      case ShareCardType.achievement:
        return 'إنجاز إيماني مبارك';
      case ShareCardType.badge:
        return 'وسام استحقاق';
      case ShareCardType.level:
        return 'المستوى المتقدم';
      case ShareCardType.invitation:
        return 'تطبيق إتقان - رفيقك الإيماني';
    }
  }

  void _onTypeChanged(ShareCardType type) {
    setState(() {
      _selectedType = type;
      _textController.text = _defaultTextFor(type);
      _subtitleController.text = _defaultSubtitleFor(type);
    });
  }

  Future<void> _shareGeneratedCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('تعذر العثور على إطار البطاقة');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('فشل تحويل الصورة');

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/itqan_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);

      String shareText = '${_textController.text}\n\n${_subtitleController.text}';
      if (_selectedType == ShareCardType.invitation && _referralCode.isNotEmpty) {
        shareText += '\n\nكود الدعوة الخاص بي في إتقان: $_referralCode';
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'مشاركة من تطبيق إتقان',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء بطاقة المشاركة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text(
          'بطاقات المشاركة الاجتماعية',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط اختيار نوع البطاقة
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: ShareCardType.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = ShareCardType.values[index];
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    selected: isSelected,
                    onSelected: (_) => _onTypeChanged(type),
                    avatar: Icon(
                      type.icon,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF0A5C36),
                    ),
                    label: Text(type.title),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF202B24),
                    ),
                    selectedColor: const Color(0xFF0A5C36),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0A5C36) : const Color(0xFFE7E0D5),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // معاينة البطاقة الرسومية
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: _buildCardView(),
              ),
            ),
            const SizedBox(height: 20),

            // تحرير النصوص
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E0D5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تخصيص نص البطاقة:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'النص الرئيسي',
                      filled: true,
                      fillColor: const Color(0xFFF9F6F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _subtitleController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'المصدر أو التوضيح',
                      filled: true,
                      fillColor: const Color(0xFFF9F6F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_selectedType == ShareCardType.invitation && _referralCode.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EEE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            'كود الإحالة: $_referralCode',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A5C36)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0A5C36)),
                            tooltip: 'نسخ الكود كنص',
                            onPressed: () {
                              ReferralService.copyCodeToClipboard(_referralCode);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ كود الإحالة')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر المشاركة النهائي عبر Android Sharesheet
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _shareGeneratedCard,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_rounded),
              label: Text(
                _isExporting ? 'جارٍ تحضير البطاقة...' : 'مشاركة البطاقة عبر التطبيقات',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C36),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A5C36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // رأس البطاقة الإسلامي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  ItqanPointsIcon(size: 16),
                  SizedBox(width: 6),
                  Text(
                    'إتقان',
                    style: TextStyle(
                      color: Color(0xFFFFF4D0),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                ),
                child: Text(
                  _selectedType.title,
                  style: const TextStyle(color: Color(0xFFFFF4D0), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // رمز البطاقة الرسومي
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37)),
            ),
            child: Icon(
              _selectedType.icon,
              color: const Color(0xFFFFF4D0),
              size: 28,
            ),
          ),
          const SizedBox(height: 18),

          // النص الرئيسي
          Text(
            _textController.text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.6,
              fontFamily: 'NotoNaskhArabic',
            ),
          ),
          const SizedBox(height: 16),

          // المصدر / التوضيح
          Text(
            _subtitleController.text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: const Color(0xFFFFF4D0).withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          // حالة كود الإحالة داخل البطاقة
          if (_selectedType == ShareCardType.invitation && _referralCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Text(
                'كود الدعوة: $_referralCode',
                style: const TextStyle(
                  color: Color(0xFFFFF4D0),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: Color(0x33D4AF37)),
          const SizedBox(height: 8),

          // تذييل البطاقة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'تطبيق إتقان • نحو إتقان العبادة وتدبر القرآن',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

