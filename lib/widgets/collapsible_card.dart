import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/preferences_service.dart';
import 'app_card.dart';

/// Status indicator for collapsible cards
enum CollapsibleCardStatus {
  configured,
  needsAttention,
  unconfigured,
}

/// A collapsible card widget with animations and state management.
/// Centralized to match MyTemplate design guide.
/// Supports persistence of expansion state via PreferencesService.
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    required this.title,
    required this.subtitle,
    required this.collapsedSummary,
    required this.expandedContent,
    super.key,
    this.cardId,
    this.status,
    this.initiallyCollapsed = true,
    this.onExpandedChanged,
    this.cardDecoration, // Maintained for transition, but internal prefers AppCardContainer
  });

  final String? cardId;
  final BoxDecoration? cardDecoration;
  final String title;
  final String subtitle;
  final Widget collapsedSummary;
  final Widget expandedContent;
  final CollapsibleCardStatus? status;
  final bool initiallyCollapsed;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final _prefs = PreferencesService.instance;

  @override
  void initState() {
    super.initState();
    // Initialize with default value immediately to prevent LateInitializationError
    _isExpanded = !widget.initiallyCollapsed;
    // Then load saved state asynchronously
    _loadSavedState();

    _animationController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Set initial animation state
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  /// Load expansion state from preferences
  Future<void> _loadSavedState() async {
    if (widget.cardId == null) return;

    await _prefs.initialize();
    final prefKey = 'card_expanded_${widget.cardId}';
    final savedState =
        _prefs.getBool(prefKey, defaultValue: !widget.initiallyCollapsed);

    if (mounted && savedState != _isExpanded) {
      setState(() {
        _isExpanded = savedState;
        if (_isExpanded) {
          _animationController.value = 1.0;
        } else {
          _animationController.value = 0.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() async {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onExpandedChanged?.call(_isExpanded);
    });

    // Save expanded state to preferences if card has an ID
    if (widget.cardId != null) {
      final prefKey = 'card_expanded_${widget.cardId}';
      await _prefs.setBool(prefKey, _isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.cardBorderRadius)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    if (widget.status != null) ...[
                      _buildStatusIndicator(widget.status!),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: _buildCollapsedContent(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.medium,
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(CollapsibleCardStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color color;
    final IconData icon;

    switch (status) {
      case CollapsibleCardStatus.configured:
        color = colorScheme.primary;
        icon = Icons.check_circle_rounded;
      case CollapsibleCardStatus.needsAttention:
        color = colorScheme.error;
        icon = Icons.warning_rounded;
      case CollapsibleCardStatus.unconfigured:
        color = colorScheme.outline;
        icon = Icons.circle_outlined;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildCollapsedContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: widget.collapsedSummary,
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: widget.expandedContent,
    );
  }
}
