import 'package:flutter/material.dart';
import '../models/template_style.dart';
import '../widgets/template_style_card.dart';

/// Dialog for selecting PDF template style
class TemplateStylePickerDialog extends StatefulWidget {
  const TemplateStylePickerDialog({
    required this.onStyleSelected,
    super.key,
  });

  final Function(TemplateStyle) onStyleSelected;

  @override
  State<TemplateStylePickerDialog> createState() =>
      _TemplateStylePickerDialogState();
}

class _TemplateStylePickerDialogState extends State<TemplateStylePickerDialog> {
  TemplateStyle? _selectedStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.style,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Template Style',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a professional template style for your PDF',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Template grid
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid: 2 columns on narrow screens, 3 on wide
                    final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                    final templates = TemplateStyle.allPresets;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: templates.map((style) {
                        final isSelected = _selectedStyle?.type == style.type;
                        return SizedBox(
                          width: (constraints.maxWidth -
                                  (16 * (crossAxisCount - 1))) /
                              crossAxisCount,
                          child: TemplateStyleCard(
                            style: style,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedStyle = style),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Help text
                  if (_selectedStyle != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedStyle!.type.label} selected',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        'Select a template style to continue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                  // Action buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _selectedStyle != null
                            ? () {
                                widget.onStyleSelected(_selectedStyle!);
                                Navigator.pop(context);
                              }
                            : null,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Preview PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
