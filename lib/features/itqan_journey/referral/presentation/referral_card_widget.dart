import 'package:flutter/material.dart';
import '../../../../shared/widgets/itqan_points_icon.dart';
import '../services/referral_service.dart';

class ReferralCardWidget extends StatefulWidget {
  const ReferralCardWidget({super.key});

  @override
  State<ReferralCardWidget> createState() => _ReferralCardWidgetState();
}

class _ReferralCardWidgetState extends State<ReferralCardWidget> {
  String _code = '...';
  int _referralCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final code = await ReferralService.getOrCreateMyReferralCode();
    final count = await ReferralService.getReferralCount();
    if (mounted) {
      setState(() {
        _code = code;
        _referralCount = count;
        _loading = false;
      });
    }
  }

  void _copy() async {
    await ReferralService.copyCodeToClipboard(_code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ كود الإحالة بنجاح',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Color(0xFF0A5C36),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _share() async {
    await ReferralService.shareReferralMessage(_code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A5C36).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A5C36).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF0A5C36),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ادعُ صديقاً إلى إتقان',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202B24),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'شارك كودك الشخصي لنيل الأجر والمكافأة الإيمانية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F685F),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // صندوق عرض الكود بخط كبير وقابل للتحديد
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7E0D5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'نسخ الكود',
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF0A5C36)),
                  onPressed: _copy,
                ),
                Expanded(
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : SelectableText(
                            _code,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                              color: Color(0xFF0A5C36),
                              fontFamily: 'Courier',
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                  ),
                ),
                const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط مطولاً على الكود لتحديده ونسخه يدوياً',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8A8C83),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),

          // أزرار النسخ والمشاركة
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('نسخ الكود'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5C36),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('مشاركة الكود'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A5C36),
                    side: const BorderSide(color: Color(0xFF0A5C36), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // إحصائية الإحالات
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EEE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$_referralCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202B24),
                      ),
                    ),
                    const Text(
                      'الأصدقاء المنضمون',
                      style: TextStyle(fontSize: 11, color: Color(0xFF5F685F)),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE7E0D5)),
                Column(
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const ItqanPointsIcon(size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_referralCount * 100}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A5C36),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'نقاط الدعوات المكتسبة',
                      style: TextStyle(fontSize: 11, color: Color(0xFF5F685F)),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

