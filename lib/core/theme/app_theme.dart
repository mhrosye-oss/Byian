import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final baseText = GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme);
    final textTheme = baseText.apply(
      bodyColor: ItqanColors.ink,
      displayColor: ItqanColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ItqanColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ItqanColors.emerald,
        brightness: Brightness.light,
      ).copyWith(
        primary: ItqanColors.emerald,
        onPrimary: ItqanColors.white,
        secondary: ItqanColors.roseGold,
        onSecondary: ItqanColors.white,
        surface: ItqanColors.surface,
        onSurface: ItqanColors.ink,
        error: ItqanColors.error,
        onError: ItqanColors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: ItqanColors.surface,
        elevation: 2,
        shadowColor: ItqanColors.ink.withOpacity(0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ItqanColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ItqanColors.cream,
        foregroundColor: ItqanColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ItqanColors.surface,
        selectedItemColor: ItqanColors.emerald,
        unselectedItemColor: ItqanColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ItqanColors.surface,
        indicatorColor: ItqanColors.emerald.withOpacity(0.10),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: GoogleFonts.tajawal().fontFamily,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? ItqanColors.emerald
                  : ItqanColors.muted,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ItqanColors.emerald,
          foregroundColor: ItqanColors.white,
          textStyle: TextStyle(
            fontFamily: GoogleFonts.tajawal().fontFamily,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ItqanRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ItqanColors.surface,
        hintStyle: const TextStyle(color: ItqanColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: const BorderSide(color: ItqanColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: const BorderSide(color: ItqanColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.md),
          borderSide: const BorderSide(color: ItqanColors.emerald, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ItqanColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerColor: ItqanColors.border,
      iconTheme: const IconThemeData(color: ItqanColors.inkSoft),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ItqanColors.emeraldDark,
        contentTextStyle: TextStyle(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          color: ItqanColors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Compatibility alias for any un-migrated legacy feature.
  static ThemeData get dark => light;
}
