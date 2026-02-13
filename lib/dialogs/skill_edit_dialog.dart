import 'package:flutter/material.dart';
import '../models/user_data/skill.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

/// Dialog for adding or editing a skill
class SkillEditDialog extends StatefulWidget {
  const SkillEditDialog({
    this.skill,
    super.key,
  });

  final Skill? skill;

  @override
  State<SkillEditDialog> createState() => _SkillEditDialogState();
}

class _SkillEditDialogState extends State<SkillEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  SkillLevel _selectedLevel = SkillLevel.intermediate;

  @override
  void initState() {
    super.initState();
    if (widget.skill != null) {
      _nameController.text = widget.skill!.name;
      _categoryController.text = widget.skill!.category ?? '';
      _selectedLevel = widget.skill!.level ?? SkillLevel.intermediate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final skill = (widget.skill ?? Skill(name: '')).copyWith(
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      level: _selectedLevel,
    );

    Navigator.pop(context, skill);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.stars_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.skill == null ? context.tr('add_skill') : context.tr('edit_skill'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr('skill_name_label'),
                  hintText: context.tr('skill_name_hint'),
                  prefixIcon: const Icon(Icons.psychology_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('please_enter_skill');
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category field
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: context.tr('category_optional'),
                  hintText: context.tr('category_hint'),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Proficiency Level
              Text(
                context.tr('proficiency_level'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: SkillLevel.values.map((level) {
                  final isSelected = _selectedLevel == level;
                  return ChoiceChip(
                    label: Text(context.tr(level.localizationKey)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedLevel = level);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(context.tr('save_skill')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
