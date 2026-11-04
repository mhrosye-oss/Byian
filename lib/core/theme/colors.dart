import 'package:flutter/material.dart';

/// Brand tokens for Itqan's light-only visual identity.
class ItqanColors {
  ItqanColors._();

  static const Color cream = Color(0xFFF9F6F0);
  static const Color emerald = Color(0xFF0A5C36);
  static const Color emeraldDark = Color(0xFF064426);
  static const Color roseGold = Color(0xFFB76E79);
  static const Color roseGoldLight = Color(0xFFD69AA3);

  static const Color surface = Color(0xFFFFFEFC);
  static const Color surfaceSoft = Color(0xFFF2EEE7);
  static const Color border = Color(0xFFE7E0D5);
  static const Color ink = Color(0xFF202B24);
  static const Color inkSoft = Color(0xFF5F685F);
  static const Color muted = Color(0xFF8A8C83);
  static const Color white = Color(0xFFFFFFFF);

  // Legacy aliases keep older feature screens aligned while they migrate.
  static const Color void_ = cream;
  static const Color obsidian = surface;
  static const Color onyx = surface;
  static const Color charcoal = border;
  static const Color slate = Color(0xFF77766F);
  static const Color mist = muted;
  static const Color silver = inkSoft;
  static const Color cloud = Color(0xFFD5D0C7);
  static const Color snow = ink;
  static const Color goldDeep = emeraldDark;
  static const Color gold = emerald;
  static const Color goldLight = roseGold;
  static const Color goldGlow = Color(0x33B76E79);
  static const Color goldShimmer = Color(0x14B76E79);

  // Feedback colors retain readable contrast on the cream background.
  static const Color correct = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF3B6F91);

  // Tajweed palette. These are visual cues; rule identification should come
  // from verified annotations/phonemizer output, not letter shape alone.
  static const Color tajweedIdgham = Color(0xFF0A5C36);
  static const Color tajweedIkhfa = Color(0xFFB76E79);
  static const Color tajweedIqlab = Color(0xFF725A9B);
  static const Color tajweedMadd = Color(0xFF286A8A);
  static const Color tajweedQalqalah = Color(0xFF9A6A12);
  static const Color tajweedGhunnah = Color(0xFF2F7770);
}
