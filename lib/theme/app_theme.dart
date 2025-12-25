import 'package:flutter/material.dart';

/// Application theme configuration based on Design System
///
/// Defines all color values, text styles, and theme data
/// for both light and dark modes. Accent colors are customizable.
class AppTheme {
  AppTheme._();

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  static const Color lightPrimary = Color(0xFF4F46E5);
  static const Color lightSecondary = Color(0xFF6B7280);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightDanger = Color(0xFFEF4444);
  static const Color lightWarning = Color(0xFFF1C232);
  static const Color lightInfo = Color(0xFF3B82F6);
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightHover = Color(0xFFF3F4F6);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  static const Color darkPrimary = Color(0xFF6366F1);
  static const Color darkSecondary = Color(0xFF9CA3AF);
  static const Color darkSuccess = Color(0xFF10B981);
  static const Color darkDanger = Color(0xFFEF4444);
  static const Color darkWarning = Color(0xFFF1C232);
  static const Color darkInfo = Color(0xFF3B82F6);
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkHover = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  static const Color statusDraft = Color(0xFF9CA3AF);
  static const Color statusApplied = Color(0xFF3B82F6);
  static const Color statusInterviewing = Color(0xFFF59E0B);
  static const Color statusOffered = Color(0xFF8B5CF6);
  static const Color statusAccepted = Color(0xFF10B981);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusWithdrawn = Color(0xFF6B7280);

  // ============================================================================
  // LAYOUT CONSTANTS
  // ============================================================================

  /// Custom header/titlebar height
  static const double headerHeight = 60;

  /// Tab bar height
  static const double tabBarHeight = 48;

  /// Header shadow (subtle bottom shadow)
  static List<BoxShadow> get lightHeaderShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Get the light theme with custom accent color
  static ThemeData lightTheme([Color accentColor = lightPrimary]) =>
      ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: accentColor,
          secondary: lightSecondary,
          surface: lightSurface,
          error: lightDanger,
        ),
        scaffoldBackgroundColor: lightBackground,
        cardColor: lightSurface,
        dividerColor: lightBorder,
        appBarTheme: const AppBarTheme(
          backgroundColor: lightSurface,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: lightDanger),
          ),
          labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: lightTextPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: const BorderSide(color: lightBorder),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cardTheme: CardThemeData(
          color: lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: lightBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: lightSurface,
          contentTextStyle: const TextStyle(
            color: lightTextPrimary,
            fontSize: 14,
          ),
          actionTextColor: accentColor,
          elevation: 3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: lightBorder),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          dense: false,
          titleTextStyle: TextStyle(
            color: lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: TextStyle(color: lightTextSecondary, fontSize: 12),
        ),
        iconTheme: const IconThemeData(color: lightTextSecondary, size: 20),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: lightTextPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: lightTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            color: lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            color: lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: lightTextPrimary, fontSize: 14),
          bodySmall: TextStyle(color: lightTextSecondary, fontSize: 12),
          labelLarge: TextStyle(
            color: lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(color: lightTextSecondary, fontSize: 12),
          labelSmall: TextStyle(color: lightTextSecondary, fontSize: 11),
        ),
      );

  /// Get the dark theme with custom accent color
  static ThemeData darkTheme([Color accentColor = darkPrimary]) =>
      ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          secondary: darkSecondary,
          surface: darkSurface,
          error: darkDanger,
        ),
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkSurface,
        dividerColor: darkBorder,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: darkDanger),
          ),
          labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTextPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: const BorderSide(color: darkBorder),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkSurface,
          contentTextStyle:
              const TextStyle(color: darkTextPrimary, fontSize: 14),
          actionTextColor: accentColor,
          elevation: 3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: darkBorder),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          dense: false,
          titleTextStyle: TextStyle(
            color: darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: TextStyle(color: darkTextSecondary, fontSize: 12),
        ),
        iconTheme: const IconThemeData(color: darkTextSecondary, size: 20),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: darkTextPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: darkTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            color: darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            color: darkTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: darkTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: darkTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: darkTextPrimary, fontSize: 14),
          bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12),
          labelLarge: TextStyle(
            color: darkTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: TextStyle(color: darkTextSecondary, fontSize: 12),
          labelSmall: TextStyle(color: darkTextSecondary, fontSize: 11),
        ),
      );

  /// Card decoration for light theme
  static BoxDecoration get lightCardDecoration => BoxDecoration(
        color: lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Card decoration for dark theme
  static BoxDecoration get darkCardDecoration => BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Key dimensions
  static const double cardBorderRadius = 12;
  static const double inputBorderRadius = 8;
  static const double maxContentWidth = 1200;
}
