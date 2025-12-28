import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_data_provider.dart';
import '../../dialogs/unified_import_dialog.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/collapsible_card.dart';
import '../templates/sections/personal_info_section.dart';
import '../templates/sections/skills_section.dart';
import '../templates/sections/work_experience_section.dart';
import '../templates/sections/languages_section.dart';

/// Profile Screen - Central hub for all user data
///
/// This is the master profile that feeds into all CVs and Cover Letters.
/// Users can import from YAML (using unified import) or edit directly in the GUI.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),

            // Quick Actions - YAML Import/Export
            _buildQuickActions(context),
            const SizedBox(height: 32),

            // Profile Sections
            const _ProfileSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Profile',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Master profile data for all CVs and Cover Letters • Import YAML files here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import YAML Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All YAML imports happen here • Auto-detects CV data or Cover Letter templates',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showExportDialog(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import YAML'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UnifiedImportDialog(),
    );

    if (result == true && context.mounted) {
      context.showSuccessSnackBar('Profile data imported successfully!');
    }
  }

  void _showExportDialog(BuildContext context) {
    context.showInfoSnackBar('YAML export coming soon');
  }
}

/// Profile sections with collapsible cards
class _ProfileSections extends StatelessWidget {
  const _ProfileSections();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Info Section
        const PersonalInfoSection(),
        const SizedBox(height: 16),

        // Work Experience Section
        const WorkExperienceSection(),
        const SizedBox(height: 16),

        // Education Section (placeholder)
        _buildEducationPlaceholder(context),
        const SizedBox(height: 16),

        // Skills Section
        const SkillsSection(),
        const SizedBox(height: 16),

        // Languages Section
        const LanguagesSection(),
        const SizedBox(height: 16),

        // Interests Section
        _buildInterestsSection(context),
      ],
    );
  }

  Widget _buildEducationPlaceholder(BuildContext context) {
    return CollapsibleCard(
      title: 'Education',
      subtitle: 'Your academic background',
      cardDecoration: UIUtils.getCardDecoration(context),
      collapsedSummary: Text(
        'No education added yet',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      expandedContent: UIUtils.buildEmptyState(
        context,
        icon: Icons.school_outlined,
        title: 'No Education Added',
        message: 'Add your educational background to include it in your CV.',
        action: OutlinedButton.icon(
          onPressed: () {
            context.showInfoSnackBar('Education editor coming soon');
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Education'),
        ),
      ),
    );
  }

  Widget _buildInterestsSection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final interests = userDataProvider.interests;

    return CollapsibleCard(
      title: 'Interests',
      subtitle: interests.isEmpty
          ? 'Your hobbies and interests'
          : '${interests.length} interest${interests.length == 1 ? '' : 's'}',
      cardDecoration: UIUtils.getCardDecoration(context),
      collapsedSummary: interests.isEmpty
          ? Text(
              'No interests added yet',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Wrap(
              spacing: 6,
              children: interests.take(3).map((i) => Chip(
                label: Text(i.name, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
      expandedContent: interests.isEmpty
          ? UIUtils.buildEmptyState(
              context,
              icon: Icons.interests_outlined,
              title: 'No Interests Added',
              message: 'Add your hobbies and interests to personalize your CV.',
              action: OutlinedButton.icon(
                onPressed: () {
                  context.showInfoSnackBar('Interest editor coming soon');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Interest'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.map((interest) {
                    return Chip(
                      label: Text(interest.name),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        userDataProvider.deleteInterest(interest.id);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.showInfoSnackBar('Interest editor coming soon');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Interest'),
                ),
              ],
            ),
    );
  }
}
