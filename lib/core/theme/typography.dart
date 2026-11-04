import 'package:flutter/material.dart';

import 'colors.dart';

class ItqanTypography {
  ItqanTypography._();

  static const String uiFont = 'Tajawal';
  static const String arabicFont = 'NotoNaskhArabic';

  static const TextStyle arabicLarge = TextStyle(
    fontFamily: arabicFont,
    fontSize: 32,
    height: 2.2,
    color: ItqanColors.ink,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle arabicMedium = TextStyle(
    fontFamily: arabicFont,
    fontSize: 24,
    height: 2.0,
    color: ItqanColors.ink,
  );

  static const TextStyle arabicSmall = TextStyle(
    fontFamily: arabicFont,
    fontSize: 18,
    height: 1.8,
    color: ItqanColors.inkSoft,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: uiFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: ItqanColors.ink,
    letterSpacing: -0.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: uiFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: ItqanColors.ink,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: uiFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ItqanColors.inkSoft,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ItqanColors.muted,
  );

  static const TextStyle label = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ItqanColors.inkSoft,
    letterSpacing: 0.1,
  );

  static const TextStyle gold = TextStyle(
    fontFamily: uiFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ItqanColors.emerald,
    letterSpacing: 0.1,
  );
}
