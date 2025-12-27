import 'package:flutter/material.dart';
import '../models/user_data/skill.dart';
import '../utils/ui_utils.dart';
import 'proficiency_dropdown.dart';

/// Chip-based editor for skills with inline level editing
class SkillChipEditor extends StatefulWidget {
  const SkillChipEditor({
    required this.skills,
    required this.onChanged,
    this.showCategories = false,
    this.allowEmpty = true,
    super.key,
  });

  final List<Skill> skills;
  final ValueChanged<List<Skill>> onChanged;
  final bool showCategories;
  final bool allowEmpty;

  @override
  State<SkillChipEditor> createState() => _SkillChipEditorState();
}

class _SkillChipEditorState extends State<SkillChipEditor> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  SkillLevel _selectedLevel = SkillLevel.intermediate;
  String? _editingSkillId;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_nameController.text.trim().isEmpty) return;

    final newSkill = Skill(
      name: _nameController.text.trim(),
      category: widget.showCategories && _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : null,
      level: _selectedLevel,
    );

    widget.onChanged([...widget.skills, newSkill]);
    _nameController.clear();
    _categoryController.clear();
    _selectedLevel = SkillLevel.intermediate;
  }

  void _updateSkillLevel(String skillId, SkillLevel newLevel) {
    final updatedSkills = widget.skills.map((skill) {
      if (skill.id == skillId) {
        return skill.copyWith(level: newLevel);
      }
      return skill;
    }).toList();
    widget.onChanged(updatedSkills);
  }

  void _deleteSkill(String skillId) {
    final updatedSkills = widget.skills.where((s) => s.id != skillId).toList();
    widget.onChanged(updatedSkills);
  }

  /// Get theme-aware color for skill level
  Color _getSkillLevelColor(BuildContext context, SkillLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (level) {
      case SkillLevel.beginner:
        return colorScheme.outline;
      case SkillLevel.intermediate:
        return colorScheme.primary;
      case SkillLevel.advanced:
        return colorScheme.tertiary;
      case SkillLevel.expert:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing skills as chips
        if (widget.skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.skills.map((skill) {
              return _buildSkillChip(context, skill);
            }).toList(),
          )
        else
          Text(
            'No skills added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),

        SizedBox(height: UIUtils.fieldVerticalGap),

        // Add new skill section
        Container(
          decoration: UIUtils.getSecondaryCard(context),
          padding: const EdgeInsets.all(UIUtils.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Skill',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: UIUtils.cardInternalGap),
                Row(
                  children: [
                    // Skill name input
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Skill Name',
                          hintText: 'e.g., Flutter, Python',
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
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Level dropdown
                    Expanded(
                      child: SkillLevelDropdown(
                        value: _selectedLevel,
                        onChanged: (level) {
                          if (level != null) {
                            setState(() => _selectedLevel = level);
                          }
                        },
                        label: 'Level',
                      ),
                    ),
                  ],
                ),

                // Category input (optional)
                if (widget.showCategories) ...[
                  SizedBox(height: UIUtils.cardInternalGap),
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category (Optional)',
                      hintText: 'e.g., Programming, Design',
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
                    onSubmitted: (_) => _addSkill(),
                  ),
                ],

              SizedBox(height: UIUtils.cardInternalGap),

              // Add button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _addSkill,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Skill'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(BuildContext context, Skill skill) {
    final theme = Theme.of(context);
    final isEditing = _editingSkillId == skill.id;
    final levelColor = skill.level != null
        ? _getSkillLevelColor(context, skill.level!)
        : theme.colorScheme.surfaceContainerHighest;

    if (isEditing) {
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
              // Skill name
              Flexible(
                child: Text(
                  skill.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Level dropdown (compact)
              DropdownButton<SkillLevel>(
                value: skill.level ?? SkillLevel.intermediate,
                items: SkillLevel.values.map((level) {
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
                            color: _getSkillLevelColor(context, level),
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
                }).toList(),
                onChanged: (newLevel) {
                  if (newLevel != null) {
                    _updateSkillLevel(skill.id, newLevel);
                    setState(() => _editingSkillId = null);
                  }
                },
                underline: const SizedBox(),
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
              ),

              const SizedBox(width: 4),

              // Close editing button
              InkWell(
                onTap: () => setState(() => _editingSkillId = null),
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

    // Normal chip display - tap to edit
    return Tooltip(
      message: 'Tap to edit proficiency level',
      child: InkWell(
        onTap: () => setState(() => _editingSkillId = skill.id),
        borderRadius: BorderRadius.circular(20),
        child: Chip(
        avatar: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: levelColor,
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                skill.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (skill.level != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  skill.level!.displayName,
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
        onDeleted: () => _deleteSkill(skill.id),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
