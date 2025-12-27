import 'package:flutter/material.dart';
import '../models/template_style.dart';

/// Template style card for style picker dialog
class TemplateStyleCard extends StatefulWidget {
  const TemplateStyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final TemplateStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<TemplateStyleCard> createState() => _TemplateStyleCardState();
}

class _TemplateStyleCardState extends State<TemplateStyleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : theme.dividerColor.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and selection indicator
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.style.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForTemplate(widget.style.type),
                      color: widget.style.primaryColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (widget.isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Template name
              Text(
                widget.style.type.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                widget.style.type.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Color preview
              Row(
                children: [
                  _ColorSwatch(
                    color: widget.style.primaryColor,
                    label: 'Primary',
                  ),
                  const SizedBox(width: 12),
                  _ColorSwatch(
                    color: widget.style.accentColor,
                    label: 'Accent',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Template features
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FeatureChip(
                    label: widget.style.fontFamily,
                    icon: Icons.font_download,
                  ),
                  if (widget.style.twoColumnLayout)
                    const _FeatureChip(
                      label: '2 Columns',
                      icon: Icons.view_column,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTemplate(TemplateType type) {
    switch (type) {
      case TemplateType.professional:
        return Icons.business_center;
      case TemplateType.modern:
        return Icons.palette;
      case TemplateType.creative:
        return Icons.auto_awesome;
      case TemplateType.yellow:
        return Icons.wb_sunny; // Sun icon for yellow/bright template
    }
  }
}

/// Color swatch display
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Feature chip display
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
