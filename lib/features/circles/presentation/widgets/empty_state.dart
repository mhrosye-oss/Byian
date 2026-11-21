import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class CirclesEmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  final VoidCallback onJoinTap;

  const CirclesEmptyState({
    super.key,
    required this.onCreateTap,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mosque / Circles Icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🕌',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'لم تنضم لأي دائرة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'أنشئ دائرة تجمعك بعائلتك أو أصدقائك في طاعة الله، أو انضم لدائرة قائمة باستخدام رمز الدعوة أو مسح الباركود.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ItqanColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onCreateTap,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'إنشاء دائرة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    foregroundColor: ItqanColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onJoinTap,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text(
                    'الانضمام بكود',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ItqanColors.emerald,
                    side: const BorderSide(color: ItqanColors.emerald, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

