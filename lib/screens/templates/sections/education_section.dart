import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/master_profile.dart';
import '../../../dialogs/education_edit_dialog.dart';
import '../../../constants/ui_constants.dart';
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
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM yyyy');

    final content = Padding(
      padding: showHeader ? const EdgeInsets.all(20) : EdgeInsets.zero,
      child: education.isEmpty
          ? _buildEmptyState(context, provider)
          : _buildEducationList(context, provider, education, dateFormat),
    );

    if (!showHeader) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Education',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (education.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${education.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _addEducation(context, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: UIConstants.getSecondaryButtonStyle(context),
                ),
              ],
            ),
          ),
          content,
        ],
      ),
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
    final theme = Theme.of(context);

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

        const SizedBox(height: 16),

        // Add button
        OutlinedButton.icon(
          onPressed: () => _addEducation(context, provider),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Education'),
        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edu.degree,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        edu.fieldOfStudy,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        edu.institution,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dateFormat.format(edu.startDate)} - ${edu.isCurrent ? 'Present' : dateFormat.format(edu.endDate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      if (edu.grade != null && edu.grade!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Grade: ${edu.grade}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Education'),
        content: Text(
          'Remove "${edu.degree}" from ${edu.institution}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteEducation(edu.id);
    }
  }
}
