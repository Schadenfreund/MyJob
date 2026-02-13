import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/user_data/skill.dart';
import '../utils/ui_utils.dart';
import '../theme/app_theme.dart';
import 'proficiency_dropdown.dart';

/// Chip-based editor for skills with inline level editing
class SkillChipEditor extends StatefulWidget {
  final List<Skill> skills;
  final ValueChanged<List<Skill>> onChanged;
  final Function(int)? onEditRequested;
  final bool showCategories;
  final bool allowEmpty;
  final bool hideAddSection;

  const SkillChipEditor({
    required this.skills,
    required this.onChanged,
    this.onEditRequested,
    this.showCategories = false,
    this.allowEmpty = true,
    this.hideAddSection = false,
    super.key,
  });

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
      category:
          widget.showCategories && _categoryController.text.trim().isNotEmpty
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
    switch (level) {
      case SkillLevel.expert:
        return Colors.purple;
      case SkillLevel.advanced:
        return Colors.orange;
      case SkillLevel.intermediate:
        return Colors.green;
      case SkillLevel.beginner:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group skills by category if enabled
    final categorized = <String, List<Skill>>{};
    final uncategorized = <Skill>[];

    if (widget.showCategories) {
      for (final skill in widget.skills) {
        if (skill.category != null && skill.category!.isNotEmpty) {
          categorized.putIfAbsent(skill.category!, () => []).add(skill);
        } else {
          uncategorized.add(skill);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing skills display
        if (widget.skills.isNotEmpty) ...[
          if (!widget.showCategories)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.skills.map((skill) {
                return _buildSkillChip(context, skill);
              }).toList(),
            )
          else ...[
            // Categorized skills
            ...categorized.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value
                          .map((skill) => _buildSkillChip(context, skill))
                          .toList(),
                    ),
                  ],
                ),
              );
            }),
            // Uncategorized skills
            if (uncategorized.isNotEmpty) ...[
              Text(
                context.tr('other_category'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uncategorized
                    .map((skill) => _buildSkillChip(context, skill))
                    .toList(),
              ),
            ],
          ],
        ] else
          UIUtils.buildEmptyState(
            context,
            icon: Icons.psychology_outlined,
            title: context.tr('no_skills_added'),
            message: context.tr('no_skills_message'),
          ),

        const SizedBox(height: AppSpacing.lg),

        // Add new skill section
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
                      context.tr('add_new_skill'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skill name input
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: context.tr('skill_name'),
                          hintText: 'e.g., Flutter, Python',
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Level dropdown
                    Expanded(
                      child: SkillLevelDropdown(
                        value: _selectedLevel,
                        onChanged: (level) {
                          if (level != null) {
                            setState(() => _selectedLevel = level);
                          }
                        },
                        label: context.tr('proficiency'),
                      ),
                    ),
                  ],
                ),

                // Category input (optional)
                if (widget.showCategories) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: context.tr('category_optional'),
                      hintText: 'e.g., Programming, Design',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    ),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr('add_to_list')),
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
    final levelColor =
        _getSkillLevelColor(context, skill.level ?? SkillLevel.intermediate);

    if (isEditing && !widget.hideAddSection) {
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
              skill.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<SkillLevel>(
              value: skill.level,
              items: SkillLevel.values.map((level) {
                final color = _getSkillLevelColor(context, level);
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
                          color: color,
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
            InkWell(
              onTap: () => setState(() => _editingSkillId = null),
              child: Icon(
                Icons.check,
                size: 18,
                color: theme.colorScheme.primary,
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
              final index = widget.skills.indexWhere((s) => s.id == skill.id);
              if (index != -1) widget.onEditRequested!(index);
            } else {
              setState(() => _editingSkillId = skill.id);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  skill.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
                if (skill.level != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.tr((skill.level ?? SkillLevel.intermediate)
                          .localizationKey)
                          .toUpperCase(),
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
                  onTap: () => _deleteSkill(skill.id),
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
