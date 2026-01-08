import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/work_experience.dart';
import '../../../dialogs/experience_edit_dialog.dart';

/// Work experience management section
class WorkExperienceSection extends StatelessWidget {
  const WorkExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final experiences = userDataProvider.sortedWorkExperiences;

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
                Icon(
                  Icons.work_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Work Experience',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${experiences.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showAddExperienceDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Experience'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: experiences.isEmpty
                ? _buildEmptyState(context)
                : _buildExperiencesList(context, experiences),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No work experience added yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencesList(
      BuildContext context, List<WorkExperience> experiences) {
    return Column(
      children: experiences.map((exp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildExperienceCard(context, exp),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceCard(BuildContext context, WorkExperience experience) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditExperienceDialog(context, experience),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            experience.position,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            experience.company,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (experience.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      experience.dateRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    if (experience.location != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        experience.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
                if (experience.description != null &&
                    experience.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    experience.description!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (experience.responsibilities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...experience.responsibilities.take(3).map((resp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              resp,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (experience.responsibilities.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${experience.responsibilities.length - 3} more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExperienceDialog(BuildContext context) {
    _showExperienceDialog(context, null);
  }

  void _showEditExperienceDialog(
      BuildContext context, WorkExperience experience) {
    _showExperienceDialog(context, experience);
  }

  void _showExperienceDialog(
      BuildContext context, WorkExperience? existingExp) async {
    final result = await showDialog<WorkExperience>(
      context: context,
      builder: (context) => ExperienceEditDialog(experience: existingExp),
    );

    if (result != null && context.mounted) {
      final provider = context.read<UserDataProvider>();
      if (existingExp == null) {
        await provider.addWorkExperience(result);
      } else {
        await provider.updateWorkExperience(result);
      }
    }
  }
}
