import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../features/quran/models/ayah.dart';

enum WordState { idle, active, correct, warning, error }

class WordToken extends StatelessWidget {
  final Word word;
  final WordState state;
  final VoidCallback? onTap;

  const WordToken({super.key, required this.word, this.state = WordState.idle, this.onTap});

  Color get _bgColor {
    return switch (state) {
      WordState.active => ItqanColors.goldGlow,
      WordState.correct => ItqanColors.correct.withOpacity(0.15),
      WordState.warning => ItqanColors.warning.withOpacity(0.15),
      WordState.error => ItqanColors.error.withOpacity(0.15),
      WordState.idle => Colors.transparent,
    };
  }

  Color get _textColor {
    final rule = word.tajweedRule?.toLowerCase() ?? '';
    final tajweedColor = rule.contains('ghunnah') || rule.contains('gunnah')
        ? ItqanColors.info
        : rule.contains('ikhfa')
            ? ItqanColors.warning
            : rule.contains('qalqalah')
                ? ItqanColors.goldLight
                : rule.contains('iqlab')
                    ? ItqanColors.error
                    : rule.contains('madd')
                        ? ItqanColors.correct
                        : rule.contains('idgham')
                            ? ItqanColors.gold
                            : ItqanColors.snow;
    return switch (state) {
      WordState.active => ItqanColors.goldLight,
      WordState.correct => ItqanColors.correct,
      WordState.warning => ItqanColors.warning,
      WordState.error => ItqanColors.error,
      WordState.idle => tajweedColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(6),
          border: state == WordState.active
              ? Border.all(color: ItqanColors.gold.withOpacity(0.5))
              : null,
        ),
        child: Text(
          word.textUthmani,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 28,
            height: 2.0,
            color: _textColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
