import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/master_profile.dart';
import '../../../dialogs/education_edit_dialog.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_card.dart';
import '../../../utils/dialog_utils.dart';
import '../../../utils/ui_utils.dart';

/// Education section for master profile
///
/// Displays all education entries with CRUD operations.
/// Reuses EducationEditDialog from job applications for consistency.
class EducationSection extends StatelessWidget {
  const EducationSection({
    this.showHeader = true,
    super.key,
  });

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserDataProvider>();
    final education = provider.education;
    final dateFormat = DateFormat('MMM yyyy');

    final content = education.isEmpty
        ? _buildEmptyState(context, provider)
        : _buildEducationList(context, provider, education, dateFormat);

    if (!showHeader) {
      return content;
    }

    return AppCard(
      title: 'Education',
      icon: Icons.school_outlined,
      description: 'Your academic background and certifications',
      trailing: AppCardActionButton(
        label: 'Add',
        icon: Icons.add,
        onPressed: () => _addEducation(context, provider),
      ),
      children: [
        content,
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, UserDataProvider provider) {
    return UIUtils.buildEmptyState(
      context,
      icon: Icons.school_outlined,
      title: 'No Education Added',
      message: 'Add your educational background to include it in your CV.',
      action: FilledButton.icon(
        onPressed: () => _addEducation(context, provider),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Education'),
      ),
    );
  }

  Widget _buildEducationList(
    BuildContext context,
    UserDataProvider provider,
    List<Education> education,
    DateFormat dateFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Education cards
        ...education.map((edu) => _buildEducationCard(
              context,
              provider,
              edu,
              dateFormat,
            )),

        if (!showHeader) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _addEducation(context, provider),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Education'),
          ),
        ],
      ],
    );
  }

  Widget _buildEducationCard(
    BuildContext context,
    UserDataProvider provider,
    Education edu,
    DateFormat dateFormat,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCardContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.school,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu.degree,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    edu.fieldOfStudy,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    edu.institution,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${dateFormat.format(edu.startDate)} - ${edu.isCurrent ? 'Present' : dateFormat.format(edu.endDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (edu.grade != null && edu.grade!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Grade: ${edu.grade}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _editEducation(context, provider, edu),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _deleteEducation(context, provider, edu),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEducation(
      BuildContext context, UserDataProvider provider) async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => const EducationEditDialog(),
    );

    if (result != null) {
      provider.addEducation(result);
    }
  }

  Future<void> _editEducation(
    BuildContext context,
    UserDataProvider provider,
    Education edu,
  ) async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => EducationEditDialog(education: edu),
    );

    if (result != null) {
      provider.updateEducation(result);
    }
  }

  Future<void> _deleteEducation(
    BuildContext context,
    UserDataProvider provider,
    Education edu,
  ) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Education',
      message: 'Remove "${edu.degree}" from ${edu.institution}?',
    );

    if (confirmed == true) {
      provider.deleteEducation(edu.id);
    }
  }
}
