import 'package:flutter/material.dart';

/// Shared UI constants for consistent styling across the app
class UIConstants {
  UIConstants._(); // Private constructor to prevent instantiation

  // ============================================================================
  // CARD STYLING
  // ============================================================================

  /// Standard card decoration for all cards across the app
  static BoxDecoration getCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Subtle card decoration for nested cards
  static BoxDecoration getNestedCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  // ============================================================================
  // PADDING & SPACING
  // ============================================================================

  /// Standard padding for cards
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Standard padding for sections
  static const EdgeInsets sectionPadding = EdgeInsets.all(24);

  /// Standard padding for dialogs
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);

  /// Standard spacing values
  static const double spaceTiny = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;

  // ============================================================================
  // BUTTON STYLES
  // ============================================================================

  /// Standard primary button style (FilledButton)
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      minimumSize: const Size(0, 44), // Minimum tap target
    );
  }

  /// Standard secondary button style (OutlinedButton)
  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      minimumSize: const Size(0, 44),
    );
  }

  /// Standard text button style
  static ButtonStyle getTextButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      minimumSize: const Size(0, 44),
    );
  }

  /// Icon button style for action buttons (Edit, Delete)
  static ButtonStyle getIconButtonStyle(BuildContext context) {
    return IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      padding: const EdgeInsets.all(8),
    );
  }

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // ============================================================================
  // DIALOG CONSTRAINTS
  // ============================================================================

  static const double dialogMaxWidth = 600;
  static const double dialogMaxHeight = 800;

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ============================================================================
  // SECTION ICONS (for consistency)
  // ============================================================================

  static const Map<String, IconData> sectionIcons = {
    'personal_info': Icons.person,
    'experience': Icons.work,
    'education': Icons.school,
    'skills': Icons.star,
    'languages': Icons.language,
    'interests': Icons.favorite,
    'profile_summary': Icons.description,
    'cover_letter': Icons.mail,
    'application': Icons.work_outline,
  };
}
