import 'package:flutter/material.dart';

/// MyJob Design System - Color Palette
///
/// A comprehensive color system supporting light and dark themes.
class AppColors {
  // Light Theme Colors
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

  // Dark Theme Colors
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

  // Status Colors (Job Specific)
  static const Color statusDraft = Color(0xFF9CA3AF);
  static const Color statusApplied = Color(0xFFF59E0B);
  static const Color statusInterviewing = Color(0xFFF59E0B);
  static const Color statusOffered = Color(0xFF8B5CF6);
  static const Color statusAccepted = Color(0xFF10B981);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusWithdrawn = Color(0xFF6B7280);

  /// Helper to get color based on theme
  static Color getColor(BuildContext context, Color light, Color dark) {
    return Theme.of(context).brightness == Brightness.light ? light : dark;
  }
}

/// MyJob Design System - Spacing Scale
class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// MyJob Design System - Dimensions
class AppDimensions {
  static const double tabBarHeight = 48.0;
  static const double headerHeight = 60.0;
  static const double cardBorderRadius = 12.0;
  static const double inputBorderRadius = 8.0;
  static const double maxContentWidth = 1200.0;
  static const double tabIconSize = 18.0;
  static const double tabIconSpacing = 6.0;
  static const double tabBarLabelFontSize = 14.0;
}

/// MyJob Design System - Animation Durations
class AppDurations {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// MyJob Design System - Complete Theme
class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData lightTheme([Color accentColor = AppColors.lightPrimary]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily:
          'Inter', // Updated to Inter for premium look if available, else fallback

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        error: AppColors.lightDanger,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightHover,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.05),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.lightDanger, width: 1),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.lightTextSecondary,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.inputBorderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        backgroundColor: AppColors.lightSurface,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        actionTextColor: accentColor,
      ),

      // ListTile Theme
      listTileTheme: const ListTileThemeData(
        dense: false,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 12,
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 20,
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme([Color accentColor = AppColors.darkPrimary]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        error: AppColors.darkDanger,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkHover,
      ),

      scaffoldBackgroundColor: AppColors.darkBackground,

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextSecondary,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
          borderSide: const BorderSide(color: AppColors.darkDanger, width: 1),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.darkTextSecondary,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.inputBorderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        actionTextColor: accentColor,
      ),

      // ListTile Theme
      listTileTheme: const ListTileThemeData(
        dense: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 12,
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 20,
      ),
    );
  }

  // Card Shadow (Light Mode)
  static List<BoxShadow> get lightCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // Card Shadow (Dark Mode)
  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get lightHeaderShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get darkHeaderShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Helper for Card Decorations (used in legacy components)
  static BoxDecoration get lightCardDecoration => BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: lightCardShadow,
      );

  static BoxDecoration get darkCardDecoration => BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: darkCardShadow,
      );
}
