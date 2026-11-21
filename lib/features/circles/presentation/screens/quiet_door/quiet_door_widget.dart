import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/features/circles/application/circle_context_provider.dart';

class QuietDoorWidget extends ConsumerWidget {
  const QuietDoorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQuiet = ref.watch(quietDoorProvider);

    return Tooltip(
      message: isQuiet ? 'باب السكينة (مفعّل - وضع الهدوء التام)' : 'باب السكينة (لمس للانتقال إلى الهدوء)',
      child: InkWell(
        onTap: () {
          ref.read(quietDoorProvider.notifier).toggle();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isQuiet
                    ? 'تم إيقاف وضع السكينة والعودة إلى التنبيهات الطبيعية.'
                    : 'تم تفعيل باب السكينة.. وضع صمت محلي مريح.',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: isQuiet ? ItqanColors.ink : ItqanColors.emeraldDark,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isQuiet ? ItqanColors.emerald.withValues(alpha: 0.15) : ItqanColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isQuiet ? ItqanColors.emerald : ItqanColors.border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isQuiet ? Icons.nights_stay_rounded : Icons.door_front_door_outlined,
                size: 16,
                color: isQuiet ? ItqanColors.emerald : ItqanColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                'باب السكينة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isQuiet ? ItqanColors.emerald : ItqanColors.inkSoft,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
