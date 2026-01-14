import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

/// A wrapper that provides consistent card styling (borders, shadows, background)
class AppCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useAccentBorder;

  const AppCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.useAccentBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final accentColor = settings.accentColor;

    final cardShadow =
        isDark ? AppTheme.darkCardShadow : AppTheme.lightCardShadow;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: useAccentBorder
              ? accentColor.withOpacity(0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: useAccentBorder ? 1.5 : 1,
        ),
        boxShadow: cardShadow,
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}

/// Centralized card widget with consistent styling across the app
class AppCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;
  final Color? accentColor;
  final Widget? trailing;
  final bool useAccentBorder;

  const AppCard({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    required this.children,
    this.accentColor,
    this.trailing,
    this.useAccentBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      useAccentBorder: useAccentBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardHeader(
            icon: icon,
            title: title,
            description: description,
            accentColor: accentColor,
            trailing: trailing,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

/// Reusable card header with inline title and description
class AppCardHeader extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? description;
  final Color? accentColor;
  final Widget? trailing;

  const AppCardHeader({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.description,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final effectiveAccentColor = accentColor ?? settings.accentColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Leading section (Icon or custom widget)
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: effectiveAccentColor.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.inputBorderRadius),
            ),
            child: Icon(
              icon,
              size: 20,
              color: effectiveAccentColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],

        // Title and Description block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Trailing section
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// A standardized information row for use inside cards
class AppCardInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const AppCardInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: iconColor ?? settings.accentColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// A standardized action button with a unified design system style.
class AppCardActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isFullWidth;
  final bool isFilled;

  const AppCardActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
    this.isFullWidth = false,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final effectiveColor = color ?? settings.accentColor;

    if (isFilled) {
      final button = icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: effectiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.inputBorderRadius),
                ),
                elevation: 0,
              ),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: effectiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.inputBorderRadius),
                ),
                elevation: 0,
              ),
              child: Text(label),
            );

      if (isFullWidth) {
        return SizedBox(width: double.infinity, child: button);
      }
      return button;
    }

    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: effectiveColor,
              side: BorderSide(color: effectiveColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.inputBorderRadius),
              ),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: effectiveColor,
              side: BorderSide(color: effectiveColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.inputBorderRadius),
              ),
            ),
            child: Text(label),
          );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// A standardized section header for use inside cards
class AppCardSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;

  const AppCardSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsService>();
    final effectiveColor = color ?? settings.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A modern, accent-color-aware chip/tag widget.
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onDeleted;
  final Color? color;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.onDeleted,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final effectiveColor = color ?? settings.accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: effectiveColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: effectiveColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onDeleted,
              borderRadius: BorderRadius.circular(10),
              child: Icon(
                Icons.close,
                size: 12,
                color: effectiveColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A container for collapsed card summaries that handles the "stacked" look.
class AppCardStackedSummary extends StatelessWidget {
  final List<Widget> children;

  const AppCardStackedSummary({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
