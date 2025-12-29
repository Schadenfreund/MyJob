import 'package:flutter/material.dart';
import '../models/user_data/interest.dart';
import '../utils/ui_utils.dart';
import 'proficiency_dropdown.dart';

/// Chip-based editor for interests with optional level editing
class InterestChipEditor extends StatefulWidget {
  const InterestChipEditor({
    required this.interests,
    required this.onChanged,
    this.allowEmpty = true,
    this.showLevels = true,
    super.key,
  });

  final List<Interest> interests;
  final ValueChanged<List<Interest>> onChanged;
  final bool allowEmpty;
  final bool showLevels;

  @override
  State<InterestChipEditor> createState() => _InterestChipEditorState();
}

class _InterestChipEditorState extends State<InterestChipEditor> {
  final TextEditingController _nameController = TextEditingController();
  InterestLevel? _selectedLevel;
  String? _editingInterestId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addInterest() {
    if (_nameController.text.trim().isEmpty) return;

    final newInterest = Interest(
      name: _nameController.text.trim(),
      level: widget.showLevels ? _selectedLevel : null,
    );

    widget.onChanged([...widget.interests, newInterest]);
    _nameController.clear();
    _selectedLevel = null;
  }

  void _updateInterestLevel(String interestId, InterestLevel? newLevel) {
    final updatedInterests = widget.interests.map((interest) {
      if (interest.id == interestId) {
        return interest.copyWith(level: newLevel);
      }
      return interest;
    }).toList();
    widget.onChanged(updatedInterests);
  }

  void _deleteInterest(String interestId) {
    final updatedInterests =
        widget.interests.where((i) => i.id != interestId).toList();
    widget.onChanged(updatedInterests);
  }

  /// Get theme-aware color for interest level
  Color _getLevelColor(BuildContext context, InterestLevel? level) {
    final colorScheme = Theme.of(context).colorScheme;

    if (level == null) return colorScheme.outline;

    switch (level) {
      case InterestLevel.casual:
        return colorScheme.outline;
      case InterestLevel.moderate:
        return colorScheme.primary;
      case InterestLevel.passionate:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing interests as chips
        if (widget.interests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.interests.map((interest) {
              return _buildInterestChip(context, interest);
            }).toList(),
          )
        else
          Text(
            'No interests added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),

        SizedBox(height: UIUtils.fieldVerticalGap),

        // Add new interest section
        Container(
          decoration: UIUtils.getSecondaryCard(context),
          padding: const EdgeInsets.all(UIUtils.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Interest',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: UIUtils.cardInternalGap),
              Row(
                children: [
                  // Interest name input
                  Expanded(
                    flex: widget.showLevels ? 2 : 1,
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Interest Name',
                        hintText: 'e.g., Photography, Hiking',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      onSubmitted: (_) => _addInterest(),
                    ),
                  ),

                  // Level dropdown (optional)
                  if (widget.showLevels) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: InterestLevelDropdown(
                        value: _selectedLevel,
                        onChanged: (level) {
                          setState(() => _selectedLevel = level);
                        },
                        label: 'Level (Optional)',
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIUtils.cardInternalGap),

              // Add button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _addInterest,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Interest'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChip(BuildContext context, Interest interest) {
    final theme = Theme.of(context);
    final isEditing = _editingInterestId == interest.id;
    final levelColor = _getLevelColor(context, interest.level);

    if (isEditing && widget.showLevels) {
      // Show dropdown when editing
      return IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Interest name
              Flexible(
                child: Text(
                  interest.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Level dropdown (compact, nullable)
              DropdownButton<InterestLevel?>(
                value: interest.level,
                items: [
                  DropdownMenuItem<InterestLevel?>(
                    value: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'None',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ...InterestLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getLevelColor(context, level),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            level.displayName,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (newLevel) {
                  _updateInterestLevel(interest.id, newLevel);
                  setState(() => _editingInterestId = null);
                },
                underline: const SizedBox(),
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
              ),

              const SizedBox(width: 4),

              // Close editing button
              InkWell(
                onTap: () => setState(() => _editingInterestId = null),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal chip display
    final chipWidget = InkWell(
      onTap: widget.showLevels
          ? () => setState(() => _editingInterestId = interest.id)
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        avatar: interest.level != null
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: levelColor,
                ),
              )
            : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                interest.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (interest.level != null && widget.showLevels) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  interest.level!.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () => _deleteInterest(interest.id),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    // Add tooltip if levels are enabled
    if (widget.showLevels) {
      return Tooltip(
        message: 'Tap to edit interest level',
        child: chipWidget,
      );
    }

    return chipWidget;
  }
}
