import 'package:flutter/material.dart';

/// Reusable collapsible section card for profile data
///
/// Provides consistent styling across all profile sections with:
/// - Collapsible header with icon and count badge
/// - Action button in header
/// - Smooth expand/collapse animation
/// - Accent color support for highlighting
class ProfileSectionCard extends StatefulWidget {
  const ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.content,
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

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        widget.useAccentColor ? theme.colorScheme.primary : null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.useAccentColor
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: widget.useAccentColor ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Material(
            color: widget.useAccentColor
                ? theme.colorScheme.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (accentColor ?? theme.colorScheme.primary)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: accentColor ?? theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
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
                      OutlinedButton.icon(
                        onPressed: widget.onActionPressed,
                        icon: Icon(widget.actionIcon, size: 16),
                        label: Text(widget.actionLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              accentColor ?? theme.colorScheme.primary,
                          side: BorderSide(
                            color: (accentColor ?? theme.colorScheme.primary)
                                .withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Expand/collapse icon
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ],
                ),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: widget.collapsedPreview,
                  ),
                ] else if (_isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
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
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
