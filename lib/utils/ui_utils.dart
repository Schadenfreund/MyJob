import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

/// UI Utilities for consistent styling across the app.
/// Based on MyTemplate design system patterns.
class UIUtils {
  UIUtils._();

  // ============================================================================
  // SPACING & DIMENSIONS
  // ============================================================================

  static const double spacingXs = AppSpacing.xs;
  static const double spacingSm = AppSpacing.sm;
  static const double spacingMd = AppSpacing.md;
  static const double spacingLg = AppSpacing.lg;
  static const double spacingXl = AppSpacing.xl;
  static const double spacingXxl = AppSpacing.xxl;

  static const double cardPadding = AppSpacing.lg;
  static const double cardInternalGap = AppSpacing.md;
  static const double fieldVerticalGap = AppSpacing.md;

  // ============================================================================
  // DECORATIONS
  // ============================================================================

  /// Returns a standard card decoration with shadow and border.
  static BoxDecoration getCardDecoration(BuildContext context,
      {bool useAccentBorder = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final settings = context.read<SettingsService>();
    final accentColor = settings.accentColor;

    final cardShadow =
        isDark ? AppTheme.darkCardShadow : AppTheme.lightCardShadow;

    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      border: Border.all(
        color: useAccentBorder
            ? accentColor.withOpacity(0.5)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        width: useAccentBorder ? 1.5 : 1,
      ),
      boxShadow: cardShadow,
    );
  }

  /// Returns a decoration for info cards (usually with accent background).
  static BoxDecoration getInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      border: Border.all(
        color: theme.colorScheme.primary.withOpacity(0.15),
        width: 1,
      ),
    );
  }

  /// Returns a decoration for secondary cards.
  static BoxDecoration getSecondaryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return BoxDecoration(
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius - 4),
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
    );
  }

  // ============================================================================
  // SNACKBAR HELPERS
  // ============================================================================

  /// Shows a success snackbar with accent color background.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final settings = context.read<SettingsService>();
    _showSnackbar(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: settings.accentColor,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows an info snackbar with accent color background.
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final settings = context.read<SettingsService>();
    _showSnackbar(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: settings.accentColor,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows a warning snackbar with orange background.
  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showSnackbar(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange.shade700,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows an error snackbar with red background.
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackbar(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppColors.lightDanger,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Private method that builds and shows a standardized floating snackbar.
  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: foregroundColor,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        ),
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foregroundColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  // ============================================================================
  // DIALOG HELPERS
  // ============================================================================

  /// Show a confirmation dialog.
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDangerous
                ? ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // ============================================================================
  // LEGACY HELPERS (Refactored to new constants)
  // ============================================================================

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
              borderRadius:
                  BorderRadius.circular(AppDimensions.inputBorderRadius),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
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
        padding: const EdgeInsets.all(AppSpacing.xxl),
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Build an outlined button with consistent styling.
  static Widget buildOutlinedButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    // NOTE: Usually buttons should use AppCardActionButton, but keeping this for compatibility
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  static Widget buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    if (icon != null) {
      return FilledButton.icon(
          onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
    }
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
