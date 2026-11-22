import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final textTheme = ThemeData.light().textTheme.apply(
      fontFamily: ItqanTypography.uiFont,
      bodyColor: ItqanColors.ink,
      displayColor: ItqanColors.ink,
    ).copyWith(
      displayLarge: ItqanTypography.heading1,
      displayMedium: ItqanTypography.heading1,
      displaySmall: ItqanTypography.heading2,
      headlineLarge: ItqanTypography.heading1,
      headlineMedium: ItqanTypography.heading2,
      headlineSmall: ItqanTypography.heading3,
      titleLarge: ItqanTypography.heading2,
      titleMedium: ItqanTypography.heading3,
      titleSmall: ItqanTypography.label,
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
        elevation: 4,
        shadowColor: ItqanColors.ink.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ItqanColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ItqanColors.cream,
        foregroundColor: ItqanColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: ItqanTypography.headingFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ItqanColors.ink,
        ),
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
        indicatorColor: ItqanColors.emerald.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: ItqanTypography.uiFont,
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
          minimumSize: const Size.fromHeight(54),
          textStyle: TextStyle(
            fontFamily: ItqanTypography.headingFont,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: ItqanTypography.headingFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: ItqanTypography.headingFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: ItqanTypography.headingFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ItqanColors.surface,
        hintStyle: const TextStyle(color: ItqanColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.lg),
          borderSide: const BorderSide(color: ItqanColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.lg),
          borderSide: const BorderSide(color: ItqanColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ItqanRadius.lg),
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
          fontFamily: ItqanTypography.uiFont,
          color: ItqanColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Compatibility alias for any un-migrated legacy feature.
  static ThemeData get dark => light;
}
