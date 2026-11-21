import 'package:flutter/material.dart';

import '../../services/adhan_scheduler.dart';

/// بطاقة خدمة "الأذان الصوتي" — بنفس تصميم بطاقات شبكة الخدمات:
/// أيقونة داخل مربع بلون خفيف + عنوان عريض + وصف رمادي صغير +
/// خلفية بيضاء + زوايا مستديرة + ظل خفيف.
class AdhanServiceCard extends StatelessWidget {
  final VoidCallback onTap;

  const AdhanServiceCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة داخل مربع بلون ذهبي فاتح (مميز عن بقية البطاقات).
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3D8), // ذهبي فاتح
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volume_up,
                color: Color(0xFFB8860B),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'الأذان الصوتي',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F4D3A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text(
              'أذان تلقائي في وقت كل صلاة',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
