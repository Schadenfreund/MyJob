import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/user_data/interest.dart';
import '../utils/ui_utils.dart';
import '../theme/app_theme.dart';
import 'proficiency_dropdown.dart';

/// Chip-based editor for interests with optional level editing
class InterestChipEditor extends StatefulWidget {
  final List<Interest> interests;
  final ValueChanged<List<Interest>> onChanged;
  final Function(int)? onEditRequested;
  final bool allowEmpty;
  final bool showLevels;
  final bool hideAddSection;

  const InterestChipEditor({
    required this.interests,
    required this.onChanged,
    this.onEditRequested,
    this.allowEmpty = true,
    this.showLevels = true,
    this.hideAddSection = false,
    super.key,
  });

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
    if (level == null) return Theme.of(context).colorScheme.primary;

    switch (level) {
      case InterestLevel.casual:
        return Colors.blue;
      case InterestLevel.moderate:
        return Colors.green;
      case InterestLevel.passionate:
        return Colors.orange;
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
          UIUtils.buildEmptyState(
            context,
            icon: Icons.interests_outlined,
            title: context.tr('no_interests_added'),
            message: context.tr('no_interests_message'),
          ),

        const SizedBox(height: AppSpacing.lg),

        // Add new interest section
        if (!widget.hideAddSection)
          Container(
            decoration: UIUtils.getSecondaryCard(context),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('add_new_interest'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    // Interest name input
                    Expanded(
                      flex: widget.showLevels ? 2 : 1,
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: context.tr('interest_name'),
                          hintText: 'e.g., Photography, Hiking',
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        onSubmitted: (_) => _addInterest(),
                      ),
                    ),

                    // Level dropdown (optional)
                    if (widget.showLevels) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: InterestLevelDropdown(
                          value: _selectedLevel,
                          onChanged: (level) {
                            setState(() => _selectedLevel = level);
                          },
                          label: context.tr('level_optional'),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addInterest,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr('add_interest')),
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

    if (isEditing && widget.showLevels && !widget.hideAddSection) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interest.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<InterestLevel?>(
              value: interest.level,
              items: [
                DropdownMenuItem<InterestLevel?>(
                  value: null,
                  child: Text(context.tr('none'), style: theme.textTheme.bodySmall),
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
                        const SizedBox(width: 8),
                        Text(
                          context.tr(level.localizationKey),
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
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.hideAddSection && widget.onEditRequested != null) {
              final index =
                  widget.interests.indexWhere((i) => i.id == interest.id);
              if (index != -1) widget.onEditRequested!(index);
            } else if (widget.showLevels) {
              setState(() => _editingInterestId = interest.id);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  interest.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
                if (interest.level != null && widget.showLevels) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.tr(interest.level!.localizationKey).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: levelColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _deleteInterest(interest.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: levelColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
