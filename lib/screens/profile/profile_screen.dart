import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_data_provider.dart';
import '../../models/user_data/interest.dart';
import '../../constants/app_constants.dart';
import '../../dialogs/unified_import_dialog.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/collapsible_card.dart';
import '../../dialogs/interest_edit_dialog.dart';
import '../templates/sections/personal_info_section.dart';
import '../templates/sections/skills_section.dart';
import '../templates/sections/work_experience_section.dart';
import '../templates/sections/education_section.dart';
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
    final userDataProvider = context.watch<UserDataProvider>();
    final currentLang = userDataProvider.currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Language Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageButton(
                context,
                userDataProvider,
                DocumentLanguage.en,
                currentLang == DocumentLanguage.en,
              ),
              const SizedBox(width: 4),
              _buildLanguageButton(
                context,
                userDataProvider,
                DocumentLanguage.de,
                currentLang == DocumentLanguage.de,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    UserDataProvider provider,
    DocumentLanguage language,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return Material(
      color:
          isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => provider.switchLanguage(language),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                language.flag,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                language.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.textTheme.labelLarge?.color,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
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
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import YAML'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  void _showExportDialog(BuildContext context) async {
    final provider = context.read<UserDataProvider>();
    final profile = provider.currentProfile;

    if (profile == null) {
      if (context.mounted) {
        context.showErrorSnackBar('No profile data to export');
      }
      return;
    }

    try {
      // Generate JSON content (valid YAML)
      final jsonData = profile.toJson();
      final yamlContent = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Show save file dialog
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Profile as YAML',
        fileName: 'profile_${profile.language.code}.yaml',
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(yamlContent);

        if (context.mounted) {
          context.showSuccessSnackBar('Profile exported successfully!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Export failed: $e');
      }
    }
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

        // Education Section
        const EducationSection(),
        const SizedBox(height: 16),

        // Skills Section
        const SkillsSection(),
        const SizedBox(height: 16),

        // Languages Section
        const LanguagesSection(),
        const SizedBox(height: 16),

        // Interests Section
        _buildInterestsSection(context),
        const SizedBox(height: 16),

        // Default Cover Letter Section
        _buildDefaultCoverLetterSection(context),
      ],
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
              children: interests
                  .take(3)
                  .map((i) => Chip(
                        label:
                            Text(i.name, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
      expandedContent: interests.isEmpty
          ? UIUtils.buildEmptyState(
              context,
              icon: Icons.interests_outlined,
              title: 'No Interests Added',
              message: 'Add your hobbies and interests to personalize your CV.',
              action: FilledButton.icon(
                onPressed: () => _addInterest(context, userDataProvider),
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
                    return InputChip(
                      label: Text(interest.name),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onPressed: () =>
                          _editInterest(context, userDataProvider, interest),
                      onDeleted: () =>
                          _deleteInterest(context, userDataProvider, interest),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _addInterest(context, userDataProvider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Interest'),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSummarySection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final profileSummary = userDataProvider.profileSummary;
    final theme = Theme.of(context);
    final controller = TextEditingController(text: profileSummary);

    return CollapsibleCard(
      title: 'Profile Summary',
      subtitle: 'Default summary for new job applications',
      cardDecoration: UIUtils.getCardDecoration(context),
      collapsedSummary: Text(
        profileSummary.isEmpty
            ? 'No profile summary set'
            : '${profileSummary.split('\n').first.substring(0, profileSummary.split('\n').first.length > 50 ? 50 : profileSummary.split('\n').first.length)}...',
        style: theme.textTheme.bodySmall,
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This summary will be used as the starting point for all new job applications. '
            'You can customize it for each specific job.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your professional summary...\n\n'
                  'Example: Experienced professional with 5+ years in software development, '
                  'specializing in full-stack solutions and team leadership.',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              userDataProvider.updateProfileSummary(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCoverLetterSection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final coverLetterBody = userDataProvider.defaultCoverLetterBody;
    final theme = Theme.of(context);
    final controller = TextEditingController(text: coverLetterBody);

    return CollapsibleCard(
      title: 'Default Cover Letter',
      subtitle: 'Template body for new job applications',
      cardDecoration: UIUtils.getCardDecoration(context),
      collapsedSummary: Text(
        coverLetterBody.isEmpty
            ? 'No default cover letter set'
            : '${coverLetterBody.split('\n').length} paragraphs',
        style: theme.textTheme.bodySmall,
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This text will be used as the default body for new cover letters. '
            'You can customize it for each job application later.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Enter your default cover letter body...\n\n'
                  'Example:\nDear Hiring Manager,\n\n'
                  'I am writing to express my interest in the [Position] role at [Company]...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              // Debounced save would be better, but for now just save on change
              userDataProvider.updateDefaultCoverLetterBody(value);
            },
          ),
        ],
      ),
    );
  }

  // Interest management helpers
  Future<void> _addInterest(
    BuildContext context,
    UserDataProvider provider,
  ) async {
    final result = await showDialog<Interest>(
      context: context,
      builder: (context) => const InterestEditDialog(),
    );

    if (result != null) {
      provider.addInterest(result);
    }
  }

  Future<void> _editInterest(
    BuildContext context,
    UserDataProvider provider,
    Interest interest,
  ) async {
    final result = await showDialog<Interest>(
      context: context,
      builder: (context) => InterestEditDialog(interest: interest),
    );

    if (result != null) {
      provider.updateInterest(result);
    }
  }

  Future<void> _deleteInterest(
    BuildContext context,
    UserDataProvider provider,
    Interest interest,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Interest'),
        content: Text('Remove "${interest.name}"?'),
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
      provider.deleteInterest(interest.id);
    }
  }
}
