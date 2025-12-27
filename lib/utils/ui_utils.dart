import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// UI Utilities for consistent styling across the app
/// Based on Design_Template patterns
class UIUtils {
  UIUtils._();

  // ============================================================================
  // CARD DECORATIONS
  // ============================================================================

  /// Get card decoration based on theme brightness (legacy method, maintained for compatibility)
  static BoxDecoration getCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Primary card decoration with moderate elevation for important cards
  static BoxDecoration getPrimaryCard(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(radiusMd),
      boxShadow: AppTheme.elevation2Shadow(Theme.of(context).colorScheme),
    );
  }

  /// Secondary card decoration with subtle elevation for supporting cards
  static BoxDecoration getSecondaryCard(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(radiusMd),
      boxShadow: AppTheme.elevation1Shadow(Theme.of(context).colorScheme),
    );
  }

  /// Info card decoration with colored background for informational content
  static BoxDecoration getInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(radiusSm),
      border: Border.all(
        color: colorScheme.primary.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  /// Get subtle background color for sections
  static Color getSectionBackground(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.02);
  }

  // ============================================================================
  // SPACING CONSTANTS
  // ============================================================================

  /// Standard spacing constants
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  /// Typography spacing for label-to-input relationships
  static const double labelTopPadding = 12.0;
  static const double labelBottomPadding = 8.0;
  static const double sectionTitleBottom = 12.0;
  static const double sectionDescriptionBottom = 16.0;

  /// Form spacing for field relationships
  static const double fieldVerticalGap = 20.0; // Between form fields
  static const double sectionGap = 32.0; // Between major sections

  /// Card spacing for internal padding
  static const double cardPadding = 20.0;
  static const double cardInternalGap = 16.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Standard border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  /// Build a section header widget
  static Widget buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: spacingMd),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  /// Build an empty state widget
  static Widget buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: spacingLg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacingSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: spacingLg),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // STANDARDIZED BUTTONS
  // ============================================================================

  /// Primary action button - use for main CTAs
  static Widget buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.check, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 40),
      ),
    );
  }

  /// Secondary action button - use for less prominent actions
  static Widget buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.check, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  /// Compact action button - use for inline actions in cards
  static Widget buildCompactButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.check, size: 14),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  /// Outlined button - use for tertiary actions
  static Widget buildOutlinedButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: Size(fullWidth ? double.infinity : 0, 44),
      ),
    );
  }

  /// Icon-only action button - use for edit/delete/etc actions in cards
  static Widget buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
    double size = 20,
  }) {
    return IconButton(
      icon: Icon(icon, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      color: color,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Standard dialog actions (Cancel + Primary action)
  static List<Widget> buildDialogActions({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmLabel,
    IconData confirmIcon = Icons.check,
    bool loading = false,
  }) {
    return [
      TextButton(
        onPressed: loading ? null : onCancel,
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: loading ? null : onConfirm,
        icon: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(confirmIcon, size: 16),
        label: Text(confirmLabel),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    ];
  }

  /// Destructive dialog actions (Cancel + Delete/Remove action)
  static List<Widget> buildDestructiveDialogActions(
    BuildContext context, {
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmLabel,
    IconData confirmIcon = Icons.delete,
  }) {
    final theme = Theme.of(context);
    return [
      TextButton(
        onPressed: onCancel,
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: onConfirm,
        icon: Icon(confirmIcon, size: 16),
        label: Text(confirmLabel),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    ];
  }
}
