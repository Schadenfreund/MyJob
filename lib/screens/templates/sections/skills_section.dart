import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/skill.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_card.dart';
import '../../../utils/ui_utils.dart';

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
      title: 'Skills',
      icon: Icons.psychology_outlined,
      description: 'Manage your skills and expertise levels',
      trailing: AppCardActionButton(
        label: 'Add Skill',
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
      title: 'No Skills Added',
      message: 'Add your skills to highlight your expertise and strengths.',
      action: FilledButton.icon(
        onPressed: () => SkillsSection.showAddSkillDialog(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Your First Skill'),
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
          _buildSkillCategory(context, 'Other', uncategorized),
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
          title: Text(existingSkill == null ? 'Add Skill' : 'Edit Skill'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name *',
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    hintText: 'e.g., Professional, Technical',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SkillLevel>(
                  initialValue: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Level',
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  items: SkillLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.displayName),
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
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Skill name is required')),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
