import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/skill.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_card.dart';
import '../../../utils/ui_utils.dart';
import '../../../localization/app_localizations.dart';

/// Skills management section
class SkillsSection extends StatelessWidget {
  const SkillsSection({
    this.showHeader = true,
    super.key,
  });

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final skills = userDataProvider.skills;

    final content = skills.isEmpty
        ? _buildEmptyState(context)
        : _buildSkillsList(context, skills);

    if (!showHeader) {
      return content;
    }

    return AppCard(
      title: context.tr('skills'),
      icon: Icons.psychology_outlined,
      description: context.tr('skills_section_desc'),
      trailing: AppCardActionButton(
        label: context.tr('add'),
        icon: Icons.add,
        onPressed: () => SkillsSection.showAddSkillDialog(context),
      ),
      children: [
        content,
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return UIUtils.buildEmptyState(
      context,
      icon: Icons.psychology_outlined,
      title: context.tr('no_skills_added'),
      message: context.tr('no_skills_message'),
      action: FilledButton.icon(
        onPressed: () => SkillsSection.showAddSkillDialog(context),
        icon: const Icon(Icons.add, size: 18),
        label: Text(context.tr('add_first_skill')),
      ),
    );
  }

  Widget _buildSkillsList(BuildContext context, List<Skill> skills) {
    // Group skills by category
    final categorized = <String, List<Skill>>{};
    final uncategorized = <Skill>[];

    for (final skill in skills) {
      if (skill.category != null && skill.category!.isNotEmpty) {
        categorized.putIfAbsent(skill.category!, () => []).add(skill);
      } else {
        uncategorized.add(skill);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categorized skills
        ...categorized.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSkillCategory(context, entry.key, entry.value),
          );
        }),
        // Uncategorized skills
        if (uncategorized.isNotEmpty)
          _buildSkillCategory(context, context.tr('other'), uncategorized),
      ],
    );
  }

  Widget _buildSkillCategory(
      BuildContext context, String category, List<Skill> skills) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              skills.map((skill) => _buildSkillChip(context, skill)).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillChip(BuildContext context, Skill skill) {
    final theme = Theme.of(context);
    final levelColor = _getLevelColor(theme, skill.level);

    return Container(
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSkillDialog(context, skill),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  skill.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: levelColor,
                  ),
                ),
                if (skill.level != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: levelColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: levelColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(ThemeData theme, SkillLevel? level) {
    if (level == null) return theme.colorScheme.primary;
    switch (level) {
      case SkillLevel.expert:
        return AppColors.statusAccepted;
      case SkillLevel.advanced:
        return AppColors.lightInfo;
      case SkillLevel.intermediate:
        return theme.colorScheme.primary;
      case SkillLevel.beginner:
        return AppColors.statusDraft;
    }
  }

  static void showAddSkillDialog(BuildContext context) {
    _showSkillDialog(context, null);
  }

  void _showEditSkillDialog(BuildContext context, Skill skill) {
    _showSkillDialog(context, skill);
  }

  static void _showSkillDialog(BuildContext context, Skill? existingSkill) {
    final nameController =
        TextEditingController(text: existingSkill?.name ?? '');
    final categoryController =
        TextEditingController(text: existingSkill?.category ?? '');
    SkillLevel selectedLevel = existingSkill?.level ?? SkillLevel.intermediate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingSkill == null ? context.tr('add_skill') : context.tr('edit_skill')),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '${context.tr('skill_name_label')} *',
                    prefixIcon: const Icon(Icons.psychology),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: context.tr('category_optional'),
                    prefixIcon: const Icon(Icons.category),
                    hintText: context.tr('category_hint'),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SkillLevel>(
                  initialValue: selectedLevel,
                  decoration: InputDecoration(
                    labelText: context.tr('proficiency_level'),
                    prefixIcon: const Icon(Icons.trending_up),
                  ),
                  items: SkillLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(context.tr(level.localizationKey)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedLevel = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (existingSkill != null)
              TextButton.icon(
                onPressed: () async {
                  await context
                      .read<UserDataProvider>()
                      .deleteSkill(existingSkill.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label:
                    Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('please_enter_skill'))),
                  );
                  return;
                }

                final skill = existingSkill?.copyWith(
                      name: nameController.text.trim(),
                      category: categoryController.text.trim().isEmpty
                          ? null
                          : categoryController.text.trim(),
                      level: selectedLevel,
                    ) ??
                    Skill(
                      name: nameController.text.trim(),
                      category: categoryController.text.trim().isEmpty
                          ? null
                          : categoryController.text.trim(),
                      level: selectedLevel,
                    );

                if (existingSkill == null) {
                  await context.read<UserDataProvider>().addSkill(skill);
                } else {
                  await context.read<UserDataProvider>().updateSkill(skill);
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}
