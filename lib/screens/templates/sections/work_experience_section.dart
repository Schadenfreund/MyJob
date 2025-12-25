import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/work_experience.dart';

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
      BuildContext context, WorkExperience? existingExp) {
    final companyController =
        TextEditingController(text: existingExp?.company ?? '');
    final positionController =
        TextEditingController(text: existingExp?.position ?? '');
    final locationController =
        TextEditingController(text: existingExp?.location ?? '');
    final descriptionController =
        TextEditingController(text: existingExp?.description ?? '');
    final responsibilitiesController = TextEditingController(
      text: existingExp?.responsibilities.join('\n') ?? '',
    );

    DateTime startDate = existingExp?.startDate ?? DateTime.now();
    DateTime? endDate = existingExp?.endDate;
    bool isCurrent = existingExp?.isCurrent ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingExp == null
              ? 'Add Work Experience'
              : 'Edit Work Experience'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company *',
                      prefixIcon: Icon(Icons.business),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: positionController,
                    decoration: const InputDecoration(
                      labelText: 'Position *',
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('MMMM yyyy').format(startDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => startDate = picked);
                      }
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Currently working here'),
                    value: isCurrent,
                    onChanged: (value) {
                      setState(() {
                        isCurrent = value ?? false;
                        if (isCurrent) endDate = null;
                      });
                    },
                  ),
                  if (!isCurrent)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date'),
                      subtitle: Text(
                        endDate != null
                            ? DateFormat('MMMM yyyy').format(endDate!)
                            : 'Not set',
                      ),
                      leading: const Icon(Icons.event),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: startDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: responsibilitiesController,
                    decoration: const InputDecoration(
                      labelText: 'Responsibilities (one per line)',
                      prefixIcon: Icon(Icons.list),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (existingExp != null)
              TextButton.icon(
                onPressed: () async {
                  await context
                      .read<UserDataProvider>()
                      .deleteWorkExperience(existingExp.id);
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
                if (companyController.text.trim().isEmpty ||
                    positionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Company and Position are required')),
                  );
                  return;
                }

                final responsibilities = responsibilitiesController.text
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .map((line) => line.trim())
                    .toList();

                final workExp = existingExp?.copyWith(
                      company: companyController.text.trim(),
                      position: positionController.text.trim(),
                      startDate: startDate,
                      endDate: endDate,
                      isCurrent: isCurrent,
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      responsibilities: responsibilities,
                    ) ??
                    WorkExperience(
                      company: companyController.text.trim(),
                      position: positionController.text.trim(),
                      startDate: startDate,
                      endDate: endDate,
                      isCurrent: isCurrent,
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      responsibilities: responsibilities,
                    );

                if (existingExp == null) {
                  await context
                      .read<UserDataProvider>()
                      .addWorkExperience(workExp);
                } else {
                  await context
                      .read<UserDataProvider>()
                      .updateWorkExperience(workExp);
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
