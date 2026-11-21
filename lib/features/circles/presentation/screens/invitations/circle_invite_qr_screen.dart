import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CircleInviteQrScreen extends StatelessWidget {
  final String circleName;
  final String code;
  final String expiresAt;

  const CircleInviteQrScreen({
    super.key,
    required this.circleName,
    required this.code,
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        title: const Text('دعوة انضمام للدائرة',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        backgroundColor: ItqanColors.cream,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ItqanColors.border),
                boxShadow: [
                  BoxShadow(
                    color: ItqanColors.ink.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: ItqanColors.emerald.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: ItqanColors.emerald, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    circleName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.ink,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'شارك هذا الكوبون لتمكين العضو من الانضمام بحسابه أو ربط جهازه',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: ItqanColors.muted,
                        fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 24),

                  // عرض رمز الكوبون النصي
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: ItqanColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: ItqanColors.ink,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: ItqanColors.emerald, size: 20),
                          tooltip: 'نسخ الرمز',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('تم نسخ رمز الكوبون إلى الحافظة')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // رمز QR التفاعلي
                  QrImageView(
                    data: code,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: ItqanColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        'صالح حتى: $expiresAt',
                        style: const TextStyle(
                            fontSize: 11,
                            color: ItqanColors.muted,
                            fontFamily: 'Tajawal'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ItqanColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعليمات الانضمام:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Tajawal'),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. يفتح العضو تطبيق إتقان وينتقل إلى "دوائري".\n2. يختار "الانضمام إلى دائرة" ويدخل الرمز أعلاه.\n3. يقوم بالمعاينة والموافقة على الانضمام.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: ItqanColors.inkSoft,
                        fontFamily: 'Tajawal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
