import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/preferences_service.dart';
import 'app_card.dart';

/// Reusable collapsible section card for profile data
///
/// Provides consistent styling across all profile sections with:
/// - Collapsible header with icon and count badge
/// - Action button in header
/// - Smooth expand/collapse animation
/// - Accent color support for highlighting
/// - Persistence of expansion state via PreferencesService
class ProfileSectionCard extends StatefulWidget {
  const ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.content,
    this.cardId,
    this.actionLabel = 'Add',
    this.actionIcon = Icons.add,
    this.onActionPressed,
    this.initiallyExpanded = true,
    this.useAccentColor = false,
    this.collapsedPreview,
    super.key,
  });

  final String title;
  final IconData icon;
  final int count;
  final Widget content;
  final String? cardId;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onActionPressed;
  final bool initiallyExpanded;
  final bool useAccentColor;
  final Widget? collapsedPreview;

  @override
  State<ProfileSectionCard> createState() => _ProfileSectionCardState();
}

class _ProfileSectionCardState extends State<ProfileSectionCard> {
  late bool _isExpanded;
  final _prefs = PreferencesService.instance;

  @override
  void initState() {
    super.initState();
    // Initialize with default value immediately to prevent LateInitializationError
    _isExpanded = widget.initiallyExpanded;
    // Then load saved state asynchronously
    _loadSavedState();
  }

  /// Load expansion state from preferences
  Future<void> _loadSavedState() async {
    if (widget.cardId == null) return;

    await _prefs.initialize();
    final prefKey = 'profile_section_${widget.cardId}';
    final savedState =
        _prefs.getBool(prefKey, defaultValue: widget.initiallyExpanded);

    if (mounted && savedState != _isExpanded) {
      setState(() {
        _isExpanded = savedState;
      });
    }
  }

  /// Toggle expansion and save to preferences
  void _toggleExpanded() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Save expanded state to preferences if card has an ID
    if (widget.cardId != null) {
      final prefKey = 'profile_section_${widget.cardId}';
      await _prefs.setBool(prefKey, _isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        widget.useAccentColor ? theme.colorScheme.primary : null;

    return AppCardContainer(
      padding: EdgeInsets.zero,
      useAccentBorder: widget.useAccentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.cardBorderRadius)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (accentColor ?? theme.colorScheme.primary)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.inputBorderRadius),
                    ),
                    child: Icon(
                      widget.icon,
                      color: accentColor ?? theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Title
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Count badge
                  if (widget.count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (accentColor ?? theme.colorScheme.primary)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor ?? theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Action button
                  if (widget.onActionPressed != null)
                    AppCardActionButton(
                      label: widget.actionLabel,
                      icon: widget.actionIcon,
                      onPressed: widget.onActionPressed!,
                      color: accentColor,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  // Expand/collapse icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                if (widget.collapsedPreview != null && !_isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: widget.collapsedPreview,
                  ),
                ] else if (_isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: widget.content,
                  ),
                ],
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : (widget.collapsedPreview != null
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst),
            duration: AppDurations.medium,
          ),
        ],
      ),
    );
  }
}
