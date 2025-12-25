import 'package:flutter/material.dart';

/// Status indicator for collapsible cards
enum CollapsibleCardStatus {
  configured,
  needsAttention,
  unconfigured,
}

/// A collapsible card widget with animations and state management.
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    required this.cardDecoration,
    required this.title,
    required this.subtitle,
    required this.collapsedSummary,
    required this.expandedContent,
    super.key,
    this.cardId,
    this.status,
    this.initiallyCollapsed = true,
    this.onExpandedChanged,
  });

  final String? cardId;
  final BoxDecoration cardDecoration;
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

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.initiallyCollapsed;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onExpandedChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardPaddingLg = 24.0;

    return Container(
      decoration: widget.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.all(cardPaddingLg),
                child: Row(
                  children: [
                    if (widget.status != null) ...[
                      _buildStatusIndicator(widget.status!),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    color: theme.textTheme.displayLarge?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodySmall?.color,
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
                        color: theme.textTheme.bodySmall?.color,
                        size: 24,
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
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(CollapsibleCardStatus status) {
    final Color color;
    final IconData icon;

    switch (status) {
      case CollapsibleCardStatus.configured:
        color = Colors.green;
        icon = Icons.check_circle;
      case CollapsibleCardStatus.needsAttention:
        color = Colors.orange;
        icon = Icons.warning_rounded;
      case CollapsibleCardStatus.unconfigured:
        color = Colors.grey;
        icon = Icons.circle_outlined;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildCollapsedContent() {
    const cardPaddingLg = 24.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        cardPaddingLg,
        0,
        cardPaddingLg,
        cardPaddingLg,
      ),
      child: widget.collapsedSummary,
    );
  }

  Widget _buildExpandedContent() {
    const cardPaddingLg = 24.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        cardPaddingLg,
        0,
        cardPaddingLg,
        cardPaddingLg,
      ),
      child: widget.expandedContent,
    );
  }
}
